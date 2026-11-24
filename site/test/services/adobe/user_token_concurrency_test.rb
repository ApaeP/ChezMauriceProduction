require "test_helper"

class Adobe::UserTokenConcurrencyTest < ActiveSupport::TestCase
  # The two workers need independent SQLite connections that see committed data.
  self.use_transactional_tests = false

  test "workers waiting on the same expired token make one refresh and observe the same new pair" do
    connection = FrameIoConnection.create!(id: 1, generation: SecureRandom.uuid, account_id: "acct", account_name: "Compte",
      access_token: "expired-access", refresh_token: "single-use", expires_at: 1.minute.ago)
    env = { "FRAME_IO_AUTH_MODE" => "user", "ADOBE_WEB_CLIENT_ID" => "client",
      "ADOBE_WEB_CLIENT_SECRET" => "secret", "ADOBE_WEB_SCOPES" => "frame-scope" }
    refresh = stub_request(:post, MediaApi::FrameIo::TOKEN_URL).with(
      body: { "grant_type" => "refresh_token", "refresh_token" => "single-use" }
    ).to_return(body: { token_type: "bearer", expires_in: 3600, access_token: "new-access", refresh_token: "new-refresh" }.to_json)

    ready = Queue.new
    start = Queue.new
    workers = 2.times.map do
      Thread.new do
        token = Adobe::UserToken.new(connection: connection, authorization: Adobe::Authorization.new(env: env))
        ready << true
        start.pop
        FrameIoConnection.connection_pool.with_connection { FrameIoConnection.cache { token.value } }
      end
    end
    workers.size.times { ready.pop }
    workers.size.times { start << true }
    assert_equal [ "new-access", "new-access" ], workers.map(&:value)
    assert_requested refresh, times: 1
    assert_equal "new-refresh", connection.reload.refresh_token
    client = Adobe::UserToken.new(connection: connection, authorization: Adobe::Authorization.new(env: env))
    client.invalidate("expired-access")
    assert connection.reload.expires_at.future?
  ensure
    connection&.destroy!
  end
end
