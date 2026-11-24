require "test_helper"
require "webmock/minitest"
require "stringio"

class Youtube::ClientTest < ActiveSupport::TestCase
  TOKEN_URL = "https://oauth2.googleapis.com/token"
  SESSION = "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=test-session"
  VIDEO_ID = "aBc123_X-yZ"
  CHANNEL_ID = "UC-test-channel"

  setup do
    @client = Youtube::Client.from_env({
      "YOUTUBE_CLIENT_ID" => "client", "YOUTUBE_CLIENT_SECRET" => "secret"
    })
    @account = YoutubeConnection.create!(id: 1, channel_id: CHANNEL_ID, channel_title: "Maurice", refresh_token: "refresh")
    @identify = stub_request(:get, Youtube::Client::CHANNEL_URL).with(headers: { "Authorization" => "Bearer access" })
      .to_return_json(body: { items: [ { id: CHANNEL_ID, snippet: { title: "Maurice" } } ] })
    stub_request(:post, TOKEN_URL).with(body: { grant_type: "refresh_token", client_id: "client",
      client_secret: "secret", refresh_token: "refresh" }).to_return_json(body: { access_token: "access",
      expires_in: 3600, token_type: "Bearer" })
  end

  test "identifie la chaîne autorisée sans conserver le jeton dans le client ou ses diagnostics" do
    assert_equal({ id: CHANNEL_ID, title: "Maurice" }, Youtube::Client.channel_for(access_token: "access"))
    assert_requested @identify, times: 1
    assert_not_requested :post, TOKEN_URL
    assert_not_includes @client.inspect, "secret"
  end

  test "refuse de créer une vidéo et de reprendre un transfert après changement de chaîne" do
    @account.update!(channel_id: "autre-chaine")
    assert_raises(Youtube::Client::ChannelUnavailable) { start_session }
    assert_raises(Youtube::Client::ChannelUnavailable) { resume("abcd") }
    assert_not_requested :post, TOKEN_URL
    assert_not_requested :put, SESSION
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  test "vérifie l’identité Google avant tout transfert même si la connexion locale porte le bon identifiant" do
    stub_request(:get, Youtube::Client::CHANNEL_URL)
      .to_return_json(body: { items: [ { id: "autre-chaine", snippet: { title: "Autre" } } ] })
    assert_raises(Youtube::Client::ChannelUnavailable) { start_session }
    assert_raises(Youtube::Client::ChannelUnavailable) { resume("abcd") }
    assert_not_requested :post, Youtube::Client::CREATE_URL
    assert_not_requested :put, SESSION
  end

  test "une liste de chaînes ambiguë ou vide échoue explicitement" do
    two_channels = [ { id: "a", snippet: { title: "A" } }, { id: "b", snippet: { title: "B" } } ]
    stub_request(:get, Youtube::Client::CHANNEL_URL).to_return_json(body: { items: [] })
      .then.to_return_json(body: { items: two_channels })
    2.times { assert_raises(Youtube::Client::ChannelUnavailable) { Youtube::Client.channel_for(access_token: "access") } }
  end

  test "demande de reconnecter le propriétaire si le refresh token est révoqué et conserve les autres erreurs OAuth" do
    stub_request(:post, TOKEN_URL).to_return_json(status: 400, body: { error: "invalid_grant" })
      .then.to_return_json(status: 400, body: { error: "invalid_client" })
      .then.to_return(status: 400, body: "Bad Request")
    assert_raises(MediaApi::Token::InvalidGrant) { resume("abcd") }
    2.times { assert_equal 400, assert_raises(MediaApi::HttpError) { resume("abcd") }.status }
    assert_not_requested :put, SESSION
  end

  test "crée uniquement une session et transmet la visibilité explicitement choisie" do
    creation = stub_request(:post, Youtube::Client::CREATE_URL).with(
      headers: { "Authorization" => "Bearer access", "X-Upload-Content-Length" => "4", "X-Upload-Content-Type" => "video/mp4" },
      body: { snippet: { title: "Essai", description: "", categoryId: "1" }, status: { privacyStatus: "private" } }
    ).to_return(status: 200, headers: { "Location" => SESSION })
    assert_equal SESSION, start_session
    assert_requested creation, times: 1
    assert_not_requested :put, SESSION
  end

  test "rejette une visibilité inconnue et les adresses extérieures au protocole" do
    assert_raises(ArgumentError) { start_session(privacy_status: "") }
    [ SESSION.sub("https:", "http:"), SESSION.sub("www.googleapis.com", "malveillant.example"),
      SESSION.sub("www.googleapis.com", "www.googleapis.com:8443"), SESSION.sub("/upload/", "/other/"),
      SESSION.sub("www.googleapis.com", "user@www.googleapis.com"), SESSION.split("?").first ].each do |invalid|
      assert_raises(Youtube::Client::ProtocolError) { resume("abcd", session_url: invalid) }
    end

    stub_request(:post, Youtube::Client::CREATE_URL).to_return(headers: { "Location" => "https://ailleurs.example/session" })
    assert_raises(Youtube::Client::ProtocolError) { start_session }
    assert_not_requested :put, /.*/
  end

  test "signale une création incertaine sans rejouer le POST" do
    creation = stub_request(:post, Youtube::Client::CREATE_URL).to_timeout
    assert_raises(MediaApi::TransportError) { start_session }
    assert_requested creation, times: 1
    assert_not_requested :put, /.*/
  end

  test "envoie plusieurs fragments de taille bornée puis accepte une plage partiellement confirmée" do
    chunk_size = Youtube::Client::CHUNK_SIZE
    source = "a".b * chunk_size + "xyz"
    probe(source.bytesize).to_return(status: 308)
    first = chunk(0, chunk_size, source.bytesize).with(body: source.byteslice(0, chunk_size))
      .to_return(status: 308, headers: { "Range" => "bytes=0-#{chunk_size - 2}" })
    last = chunk(chunk_size - 1, 4, source.bytesize).with(body: "axyz").to_return_json(status: 201, body: { id: VIDEO_ID })

    io = StringIO.new(source)
    io.define_singleton_method(:read) do |length|
      raise "Lecture non bornée" unless length.between?(1, Youtube::Client::CHUNK_SIZE)
      super(length)
    end
    assert_equal VIDEO_ID, @client.resume(expected_channel_id: CHANNEL_ID, session_url: SESSION, io: io,
      byte_size: source.bytesize, content_type: "video/mp4")
    assert_requested first, times: 1
    assert_requested last, times: 1
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  test "repart de la position confirmée après une coupure et retrouve une réponse finale perdue" do
    probe(5).to_return(status: 308, headers: { "Range" => "bytes=0-1" })
      .then.to_return_json(status: 200, body: { id: VIDEO_ID })
    lost = chunk(2, 3, 5).with(body: "cde").to_timeout
    assert_raises(MediaApi::TransportError) { resume("abcde") }
    assert_equal VIDEO_ID, resume("abcde")
    assert_requested lost, times: 1
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  test "reporte les réponses transitoires sans boucle ni nouveau POST" do
    probe(4).to_return(status: 308, headers: { "Retry-After" => "12" })
      .then.to_return(status: 503, headers: { "Retry-After" => "45" })
    assert_equal "12", assert_raises(Youtube::Client::RetryLater) { resume("abcd") }.retry_after
    assert_equal "45", assert_raises(Youtube::Client::RetryLater) { resume("abcd") }.retry_after
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  test "identifie une session expirée et une réponse incomplète sans progression" do
    probe(4).to_return(status: 404).then.to_return(status: 308)
    chunk(0, 4, 4).to_return(status: 308)
    assert_raises(Youtube::Client::SessionExpired) { resume("abcd") }
    assert_raises(Youtube::Client::RetryLater) { resume("abcd") }
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  test "refuse une taille source modifiée, une plage incohérente et une réponse finale sans identifiant" do
    assert_raises(ArgumentError) { resume("abc", byte_size: 4) }
    probe(4).to_return(status: 308, headers: { "Range" => "bytes=1-2" })
      .then.to_return(status: 308, headers: { "Range" => "bytes=0-9" })
      .then.to_return_json(status: 201, body: {})
    3.times { assert_raises(Youtube::Client::ProtocolError) { resume("abcd") } }
    assert_not_requested :post, Youtube::Client::CREATE_URL
  end

  private
    def start_session(privacy_status: "private")
      @client.start_session(expected_channel_id: CHANNEL_ID, title: "Essai", description: "", category_id: "1",
        privacy_status: privacy_status, byte_size: 4, content_type: "video/mp4")
    end

    def resume(source, byte_size: source.bytesize, session_url: SESSION)
      @client.resume(expected_channel_id: CHANNEL_ID, session_url: session_url, io: StringIO.new(source),
        byte_size: byte_size, content_type: "video/mp4")
    end

    def probe(size)
      stub_request(:put, SESSION).with(headers: { "Content-Length" => "0", "Content-Range" => "bytes */#{size}" })
    end

    def chunk(offset, length, total)
      stub_request(:put, SESSION).with(headers: { "Authorization" => "Bearer access",
        "Content-Length" => length.to_s, "Content-Range" => "bytes #{offset}-#{offset + length - 1}/#{total}" })
    end
end
