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
    @file = { id: "file-test", type: "file", project_id: "publication", status: "ready",
      media_type: "video/quicktime", name: "film.mov", file_size: 5, created_at: "2026-11-24T13:00:00.123456+01:00" }
  end

  test "a deposit in the publication project uses the original filename and needs no custom fields" do
    stub_file
    source = @client.publication_export("file-test", project_id: "publication")
    assert_equal "account-test", @client.account_id
    assert_equal [ "file-test", "publication", "film.mov", nil, "ready", 5, "video/quicktime" ],
      [ source.file_id, source.project_id, source.title, source.description, source.status, source.byte_size, source.content_type ]
    assert source.ready?
    assert_not_requested :get, "#{@endpoint}/metadata"
    assert_not_requested :get, @signed

    stub_source
    stub_request(:get, @signed).to_return(body: "12345")
    assert_equal 5, @client.download_original(source.file_id, output: StringIO.new, expected: source)
  end

  test "reads configured text fields by stable id and uses the filename if the title is empty" do
    stub_file
    text_fields = [
      { field_type: "text", field_definition_id: "editorial-title", field_definition_name: "Titre", value: "Titre validé" },
      { field_type: "text", field_definition_id: "editorial-description", value: "Premier plan.\nPlan suivant." }
    ]
    stub_metadata(text_fields)
    options = { project_id: "publication", title_field_id: "editorial-title", description_field_id: "editorial-description" }
    source = @client.publication_export("file-test", **options)
    assert_equal "Titre validé", source.title
    assert_equal "Premier plan.\nPlan suivant.", source.description

    stub_metadata([ text_fields.first.merge(value: " ") ])
    source = @client.publication_export("file-test", **options)
    assert_equal "film.mov", source.title
    assert_nil source.description
    stub_metadata([ text_fields.first.merge(field_type: "select", value: []) ])
    assert_raises(MediaApi::Error) { @client.publication_export("file-test", **options) }
  end

  test "checks the id, project, kind and declared video MIME type before fetching optional fields" do
    [ { project_id: "historical" }, { type: "folder" }, { media_type: "audio/aac" }, { media_type: nil },
      { media_type: "video/mp4\r\nX: invalid" } ].each do |change|
      stub_file(**change)
      assert_nil @client.publication_export("file-test", project_id: "publication", title_field_id: "title")
    end
    stub_file(id: "another-file")
    assert_raises(MediaApi::Error) { @client.publication_export("file-test", project_id: "publication") }
    assert_not_requested :get, "#{@endpoint}/metadata"
  end

  test "permits waiting for processing and rejects invalid sizes on a ready video" do
    stub_file(media_type: nil, status: "created", file_size: nil)
    source = @client.publication_export("file-test", project_id: "publication")
    refute source.ready?
    stub_file(file_size: 0)
    assert_raises(MediaApi::Error) { @client.publication_export("file-test", project_id: "publication") }
    stub_file(status: "transcoded", created_at: "2020-01-01T14:30:00Z")
    assert_predicate @client.publication_export("file-test", project_id: "publication"), :ready?
  end

  test "metadata belongs to the file requested and Adobe version aliases match the returned version" do
    stub_metadata([], file_id: "another-file")
    assert_raises(MediaApi::Error) { @client.metadata("file-test") }
    qualified_id = "adobe:urn:aaid:sc:US:x|2"
    url = @endpoint.sub("file-test", URI.encode_uri_component(qualified_id))
    details = @file.merge(adobe_id: "urn:aaid:sc:US:x", adobe_version_id: "2")
    stub_request(:get, url).with(headers: @bearer).to_return(body: { data: details }.to_json)
    assert_equal "file-test", @client.publication_export(qualified_id, project_id: "publication").file_id
    stub_request(:get, url).with(headers: @bearer).to_return(body: { data: details.merge(adobe_version_id: "1") }.to_json)
    assert_raises(MediaApi::Error) { @client.file(qualified_id) }
  end

  test "rejects a changed original before downloading the signed URL" do
    stub_file
    source = @client.publication_export("file-test", project_id: "publication")
    [ { id: "another-file" }, { project_id: "old" }, { type: "version_stack" },
      { status: "created" }, { file_size: 6 }, { media_type: "image/jpeg" } ].each do |change|
      stub_source(**change)
      output = StringIO.new(+"prefix", "ab")
      output.seek(0, IO::SEEK_END)
      assert_raises(MediaApi::Error) { @client.download_original(source.file_id, output: output, expected: source) }
      assert_equal "prefix", output.string
    end
    assert_not_requested :get, @signed
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
    assert_raises(MediaApi::FrameIo::OriginalUnavailable) { @client.download_original("file-test", output: StringIO.new) }
    stub_request(:get, @endpoint).with(headers: @bearer).to_return(status: 403)
    error = assert_raises(MediaApi::HttpError) { @client.file("file-test") }
    assert_equal 403, error.status
  end

  private
    def stub_file(**changes)
      stub_request(:get, @endpoint).with(headers: @bearer).to_return(body: { data: @file.merge(changes) }.to_json)
    end

    def stub_metadata(fields, file_id: "file-test")
      stub_request(:get, "#{@endpoint}/metadata").with(headers: @bearer)
        .to_return(body: { data: { file_id: file_id, metadata: fields } }.to_json)
    end

    def stub_source(url: @signed, **changes)
      stub_request(:get, "#{@endpoint}?include=media_links.original").with(headers: @bearer)
        .to_return(body: { data: @file.merge(changes).merge(media_links: { original: { download_url: url } }) }.to_json)
    end
end
