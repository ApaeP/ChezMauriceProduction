require "test_helper"
require "webmock/minitest"
require "stringio"

class MediaApi::FrameIoTest < ActiveSupport::TestCase
  setup do
    @client = MediaApi::FrameIo.from_env({
      "FRAME_IO_AUTH_MODE" => "server_to_server",
      "ADOBE_CLIENT_ID" => "client-test", "ADOBE_CLIENT_SECRET" => "secret-test",
      "ADOBE_SCOPES" => "scopes-test", "FRAME_IO_ACCOUNT_ID" => "account-test"
    })
    @auth = stub_request(:post, MediaApi::FrameIo::TOKEN_URL)
      .with(body: { grant_type: "client_credentials", scope: "scopes-test",
        client_id: "client-test", client_secret: "secret-test" })
      .to_return(status: 200, body: { access_token: "test-token", token_type: "bearer", expires_in: 3600 }.to_json)
    @endpoint = "https://api.frame.io/v4/accounts/account-test/files/file-test"
    @bearer = { "Authorization" => "Bearer test-token" }
    @signed = "https://assets.frame.io/original?signature=test"
  end

  test "loads file details and preserves the raw metadata values and field definitions" do
    fields = [ { "field_type" => "select_multi", "field_definition_id" => "field-test",
      "value" => [ { "id" => "choice-test", "display_name" => "Site" } ] } ]
    stub_request(:get, @endpoint).with(headers: @bearer)
      .to_return(body: { data: { id: "file-test", name: "technique.mov" } }.to_json)
    stub_request(:get, "#{@endpoint}/metadata").with(headers: @bearer)
      .to_return(body: { data: { file_id: "file-test", metadata: fields } }.to_json)
    assert_equal "technique.mov", @client.file("file-test").fetch("name")
    assert_equal fields, @client.metadata("file-test")
    assert_requested @auth, times: 1
  end

  test "downloads the original bytes across signed redirects without transferring Adobe credentials" do
    stub_source
    first = stub_request(:get, @signed).to_return(status: 302,
      headers: { "Location" => "https://s3.amazonaws.com/test?signature=other" }, body: "redirection")
    second = stub_request(:get, "https://s3.amazonaws.com/test?signature=other").to_return(body: "12345")
    output = StringIO.new(+"", "wb")
    assert_equal 5, @client.download_original("file-test", output: output)
    assert_equal "12345", output.string
    [ first, second ].each { |stub| assert_requested stub }
    assert_not_requested(:get, %r{https://(?:assets\.frame\.io|s3\.amazonaws\.com)/},
      headers: { "Authorization" => /.+/ })
  end

  test "rejects an unapproved redirect and leaves the output intact" do
    stub_source
    stub_request(:get, @signed).to_return(status: 307, headers: { "Location" => "https://unknown.test/film" })
    output = StringIO.new(+"", "wb")
    assert_raises(MediaApi::Error) { @client.download_original("file-test", output: output) }
    assert_empty output.string
    assert_not_requested(:get, "https://unknown.test/film")
  end

  test "detects a truncated original and erases the partial copy" do
    stub_source
    stub_request(:get, @signed).to_return(body: "12")
    output = StringIO.new(+"", "wb")
    assert_raises(MediaApi::Error) { @client.download_original("file-test", output: output) }
    assert_empty output.string
  end

  test "reports unavailable originals and propagates API errors" do
    stub_source(url: nil)
    assert_raises(MediaApi::Error) { @client.download_original("file-test", output: StringIO.new) }
    stub_request(:get, @endpoint).with(headers: @bearer).to_return(status: 403)
    error = assert_raises(MediaApi::HttpError) { @client.file("file-test") }
    assert_equal 403, error.status
  end

  private
    def stub_source(url: @signed)
      stub_request(:get, "#{@endpoint}?include=media_links.original").with(headers: @bearer)
        .to_return(body: { data: { file_size: 5, media_links: { original: { download_url: url } } } }.to_json)
    end
end
