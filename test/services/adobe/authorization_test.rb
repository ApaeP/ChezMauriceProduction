require "test_helper"

class Adobe::AuthorizationTest < ActiveSupport::TestCase
  setup do
    @env = { "FRAME_IO_AUTH_MODE" => "user", "ADOBE_WEB_CLIENT_ID" => "client",
      "ADOBE_WEB_CLIENT_SECRET" => "secret", "ADOBE_WEB_SCOPES" => "frame-scopes" }
    @oauth = Adobe::Authorization.new(redirect_uri: "https://localhost/connexion-frame-io/retour", env: @env)
    @basic = { "Authorization" => "Basic #{Base64.strict_encode64("client:secret")}" }
    @state = Digest::SHA256.hexdigest("used-state")
    @invitation = OwnerInvitation.create!(provider: "adobe", code_digest: "digest", state_digest: @state,
      state_used: true, redeemed_at: Time.current, expires_at: 15.minutes.from_now)
  end

  test "uses the confidential Web App flow and requires an explicit backend" do
    url = URI(@oauth.url(state: "one-use-state"))
    query = URI.decode_www_form(url.query).to_h
    assert_equal "ims-na1.adobelogin.com", url.host
    assert_equal %w[frame-scopes offline_access openid], query.fetch("scope").split(",").sort
    assert_equal "fragment", query.fetch("response_mode")
    assert_equal "code", query.fetch("response_type")
    assert_equal "one-use-state", query.fetch("state")
    assert_nil query["client_secret"]
    refute_includes @oauth.inspect, "secret"
    assert_raises(MediaApi::Error) { MediaApi::FrameIo.from_env({}) }
    assert_raises(MediaApi::Error) { MediaApi::FrameIo.from_env(@env) }
  end

  test "one account activates immediately, multiple accounts wait for an authenticated choice, old clients cannot refresh a replacement" do
    consent(%w[one])
    assert_equal :active, @oauth.connect!(code: "code", invitation: @invitation)
    assert_equal "one", FrameIoConnection.current.account_id
    stale_client = MediaApi::FrameIo.from_env(@env)
    @invitation.reload
    consent(%w[two three])
    assert_equal :choose_account, @oauth.connect!(code: "next", invitation: @invitation)
    assert_equal "one", FrameIoConnection.current.account_id
    assert_equal %w[two three], @invitation.reload.adobe_accounts.map { |a| a.fetch("id") }
    ciphertext = @invitation.pending_adobe_grant_before_type_cast
    assert_not_includes ciphertext, "refresh-secret"
    assert_not_includes ciphertext, "access-secret"
    selection = @invitation.pending_adobe_grant.fetch("selection_id")
    assert_raises(MediaApi::Error) { @oauth.select_account!(account_id: "two", selection_id: "old", invitation: @invitation) }
    assert_raises(MediaApi::Error) { @oauth.select_account!(account_id: "one", selection_id: selection, invitation: @invitation) }
    assert_equal "one", FrameIoConnection.current.account_id

    @oauth.select_account!(account_id: "three", selection_id: selection, invitation: @invitation)
    assert_nil @invitation.reload.pending_adobe_grant
    assert_equal "three", FrameIoConnection.current.account_id
    assert_raises(MediaApi::Error) { stale_client.file("unused") }
    assert_raises(MediaApi::Error) { @oauth.select_account!(account_id: "two", selection_id: selection, invitation: @invitation) }
    ciphertext = FrameIoConnection.connection.select_one("SELECT access_token, refresh_token FROM frame_io_connections")
    assert_not_includes ciphertext.inspect, "access-secret"
    assert_not_includes ciphertext.inspect, "refresh-secret"
  end

  test "retains the previous account on denial, missing offline grant, unavailable accounts, or replaced invitation attempt" do
    existing = active_grant
    consent([], refresh: nil)
    assert_raises(MediaApi::Error) { @oauth.connect!(code: "code", invitation: @invitation) }
    consent([])
    assert_raises(MediaApi::Error) { @oauth.connect!(code: "code", invitation: @invitation) }
    consent(%w[two])
    OwnerInvitation.where(id: @invitation.id).update_all(state_digest: "newer", state_used: false)
    assert_raises(MediaApi::Error) { @oauth.connect!(code: "code", invitation: @invitation) }
    assert_equal existing.generation, FrameIoConnection.current.generation
  end

  test "rotates both encrypted credentials, reuses the new access token and marks a revoked grant for reconnection" do
    record = active_grant
    client = MediaApi::FrameIo.from_env(@env)
    api_url = "https://api.frame.io/v4/accounts/active/files/file"
    stub_request(:get, api_url).with(headers: { "Authorization" => "Bearer renewed" }).to_return(body: '{"data":{"id":"file"}}')
    refresh = stub_request(:post, MediaApi::FrameIo::TOKEN_URL).with(headers: @basic,
      body: { "grant_type" => "refresh_token", "refresh_token" => "old-refresh" }).to_return(
      body: token_response("renewed", "next-refresh").to_json)

    2.times { assert_equal "file", client.file("file").fetch("id") }
    assert_requested refresh, times: 1
    assert_equal "next-refresh", record.reload.refresh_token
    assert_equal "renewed", record.access_token
    assert record.expires_at.future?

    record.update!(expires_at: 1.second.ago)
    revoked = stub_request(:post, MediaApi::FrameIo::TOKEN_URL).with(headers: @basic,
      body: { "grant_type" => "refresh_token", "refresh_token" => "next-refresh" }).to_return(
      status: 400, body: '{"error":"invalid_grant"}')
    2.times { assert_raises(MediaApi::Token::InvalidGrant) { client.file("file") } }
    assert_requested revoked, times: 1
    assert record.reload.reconnect_required?
    assert_nil record.access_token
  end

  private
    def active_grant
      FrameIoConnection.create!(id: 1, account_id: "active", account_name: "Active", generation: SecureRandom.uuid,
        access_token: "old", refresh_token: "old-refresh", expires_at: 1.second.ago)
    end

    def token_response(access, refresh)
      { "access_token" => access, "refresh_token" => refresh, "token_type" => "bearer", "expires_in" => 3600 }
    end

    def consent(ids, refresh: "refresh-secret")
      stub_request(:post, MediaApi::FrameIo::TOKEN_URL).with(headers: @basic,
        body: { grant_type: "authorization_code", code: /.+/ }).to_return(body: token_response("access-secret", refresh).to_json)
      accounts = ids.map { |id| { id: id, display_name: "Compte #{id}" } }
      stub_request(:get, "https://api.frame.io/v4/accounts").with(headers: { "Authorization" => "Bearer access-secret" })
        .to_return(body: { data: accounts, links: { next: nil } }.to_json)
    end
end
