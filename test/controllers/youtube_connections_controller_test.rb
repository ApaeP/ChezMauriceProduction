require "test_helper"
require "webmock/minitest"

class YoutubeConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @saved_google_env = ENV.to_h.slice("YOUTUBE_CLIENT_ID", "YOUTUBE_CLIENT_SECRET")
    ENV["YOUTUBE_CLIENT_ID"] = "client-test"
    ENV["YOUTUBE_CLIENT_SECRET"] = "secret-test"
  end

  teardown do
    ENV.delete("YOUTUBE_CLIENT_ID")
    ENV.delete("YOUTUBE_CLIENT_SECRET")
    ENV.update(@saved_google_env)
  end

  test "owner redeems a single-use invitation, validates offline permissions and stores the verified channel" do
    code = OwnerInvitation.issue!(provider: "youtube")
    post youtube_connection_path, params: { invitation_code: code }
    assert_response :see_other
    second = open_session
    second.post youtube_connection_path, params: { invitation_code: code }
    assert_equal 422, second.response.status

    oauth = start_google_consent
    assert_equal youtube_callback_url, oauth.fetch("redirect_uri")
    assert_equal "offline", oauth.fetch("access_type")
    assert_equal "fragment", oauth.fetch("response_mode")
    assert_equal Youtube::Authorization::SCOPES.sort, oauth.fetch("scope").split.sort
    assert_equal "S256", oauth.fetch("code_challenge_method")
    assert_equal "select_account consent", oauth.fetch("prompt")

    token_exchange = successful_exchange(oauth)
    lookup_channel
    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    assert_redirected_to youtube_connection_path
    assert_equal "no-store", response.headers.fetch("Cache-Control")
    assert_equal "same-origin", response.headers.fetch("Referrer-Policy")
    follow_redirect!
    assert_select "strong", text: "Chaîne autorisée"
    assert_includes response.body, "channel-test"
    assert_no_match(/refresh-test|access-test|one-use-code/, response.body)
    assert_equal "refresh-test", YoutubeConnection.current.refresh_token
    ciphertext = YoutubeConnection.connection.select_value("SELECT refresh_token FROM youtube_connections")
    assert_not_includes ciphertext, "refresh-test"
    assert_not_includes session.to_hash.inspect, "refresh-test"

    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    assert_requested token_exchange, times: 1
    second.get youtube_connection_path
    assert_not_includes second.response.body, "channel-test"
  end

  test "la recette refuse une autre chaîne et conserve le consentement précédent" do
    previous = ENV["FRAME_IO_PRIVATE_TRIAL"]
    ENV["FRAME_IO_PRIVATE_TRIAL"] = "1"
    YoutubeConnection.create!(id: 1, channel_id: FrameIoPublication::CHANNEL_ID, channel_title: "Chez Maurice Production", refresh_token: "previous")
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    oauth = start_google_consent
    successful_exchange(oauth)
    lookup_channel
    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    follow_redirect!
    assert_select "[role=alert]", text: /sélectionnez la chaîne Chez Maurice Production/
    assert_equal "previous", YoutubeConnection.current.refresh_token
    assert_equal FrameIoPublication::CHANNEL_ID, YoutubeConnection.current.channel_id
  ensure
    ENV["FRAME_IO_PRIVATE_TRIAL"] = previous
  end

  test "unauthorized, expired, mismatched and declined attempts preserve the previously connected channel" do
    YoutubeConnection.create!(id: 1, channel_id: "old", channel_title: "Ancienne chaîne", refresh_token: "previous")
    post authorize_youtube_path
    assert_redirected_to youtube_connection_path
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    oauth = start_google_consent
    post youtube_callback_path, params: { code: "secret", state: "wrong" }
    assert_redirected_to youtube_connection_path
    post youtube_callback_path, params: { error: "access_denied", state: oauth.fetch("state") }
    follow_redirect!
    assert_select "[role=alert]", text: /interrompue/
    assert_includes response.body, "Ancienne chaîne"
    assert_not_requested :post, Youtube::Client::TOKEN_URL

    travel 16.minutes do
      post authorize_youtube_path
      assert_redirected_to youtube_connection_path
      follow_redirect!
      assert_no_match(/Ancienne chaîne/, response.body)
    end
    assert_equal "previous", YoutubeConnection.current.refresh_token
  end

  test "an incomplete Google grant and a channel lookup failure never replace valid credentials" do
    YoutubeConnection.create!(id: 1, channel_id: "old", channel_title: "Ancienne chaîne", refresh_token: "previous")
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    oauth = start_google_consent
    successful_exchange(oauth, scopes: Youtube::Authorization::SCOPES.first)
    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    follow_redirect!
    assert_select "[role=alert]", text: /deux permissions/
    assert_not_requested :get, Youtube::Client::CHANNEL_URL

    oauth = start_google_consent
    successful_exchange(oauth)
    stub_request(:get, Youtube::Client::CHANNEL_URL).to_return_json(body: { items: [] })
    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    follow_redirect!
    assert_select "[role=alert]"
    assert_equal "previous", YoutubeConnection.current.refresh_token
  end

  test "starting a new authorization while Google identifies a channel supersedes the old callback" do
    YoutubeConnection.create!(id: 1, channel_id: "old", channel_title: "Ancienne chaîne", refresh_token: "previous")
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    oauth = start_google_consent
    successful_exchange(oauth)
    stub_request(:get, Youtube::Client::CHANNEL_URL).to_return do
      OwnerInvitation.find_by!(provider: "youtube").start_authorization!
      { status: 200, body: { items: [ { id: "obsolete", snippet: { title: "Ancienne tentative" } } ] }.to_json }
    end

    post youtube_callback_path, params: { code: "one-use-code", state: oauth.fetch("state") }
    follow_redirect!
    assert_select "[role=alert]", text: /remplacée/
    assert_equal "previous", YoutubeConnection.current.refresh_token
  end

  test "a query string cannot redeem a code and closing the page session removes the grant" do
    code = OwnerInvitation.issue!(provider: "youtube")
    post youtube_connection_path(invitation_code: code)
    assert_response :unprocessable_content
    post youtube_connection_path, params: { invitation_code: code }
    assert_response :see_other
    delete youtube_connection_path
    assert_redirected_to youtube_connection_path
    post authorize_youtube_path
    assert_redirected_to youtube_connection_path
    post youtube_connection_path, params: { invitation_code: code }
    assert_response :unprocessable_content
  end

  test "the landing accepts no query and only the local form can submit the OAuth response" do
    get youtube_callback_path
    assert_response :success
    assert_select "form[action=?][method=post]", youtube_callback_path
    assert_select "script[src*=owner_callback][defer]"
    assert_select "script[src^='https://']", count: 0
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    oauth = start_google_consent
    query = { code: "one-use-code", state: oauth.fetch("state") }
    get youtube_callback_path, params: query
    assert_response :bad_request
    post youtube_callback_path(query)
    assert_response :bad_request
    assert_not_requested :post, Youtube::Client::TOKEN_URL
    assert_nil YoutubeConnection.current
  end

  test "the owner form enforces CSRF before redeeming an invitation" do
    previous = YoutubeConnectionsController.allow_forgery_protection
    YoutubeConnectionsController.allow_forgery_protection = true
    code = OwnerInvitation.issue!(provider: "youtube")
    post youtube_connection_path, params: { invitation_code: code }
    assert_response :unprocessable_content
    get youtube_connection_path
    token = css_select("form input[name='authenticity_token']").first["value"]
    post youtube_connection_path, params: { invitation_code: code, authenticity_token: token }
    assert_response :see_other
    follow_redirect!
    assert_select "button", text: "Autoriser avec Google"
  ensure
    YoutubeConnectionsController.allow_forgery_protection = previous
  end

  test "an unconfigured app and an expired code keep the public site and access form available" do
    code = OwnerInvitation.issue!(provider: "youtube")
    travel 16.minutes do
      post youtube_connection_path, params: { invitation_code: code }
      assert_response :unprocessable_content
    end
    ENV.delete("YOUTUBE_CLIENT_SECRET")
    post youtube_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "youtube") }
    post authorize_youtube_path
    assert_redirected_to youtube_connection_path
    follow_redirect!
    assert_select "[role=alert]", text: /configuration/
    assert_equal "noindex, nofollow", response.headers.fetch("X-Robots-Tag")
  end

  private

  def start_google_consent
    post authorize_youtube_path
    assert_response :see_other
    location = URI.parse(response.location)
    assert_equal "accounts.google.com", location.host
    URI.decode_www_form(location.query).to_h
  end

  def successful_exchange(oauth, scopes: Youtube::Authorization::SCOPES.join(" "))
    stub_request(:post, Youtube::Client::TOKEN_URL).with do |req|
      fields = URI.decode_www_form(req.body).to_h
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(fields.fetch("code_verifier")), padding: false)
      fields.except("code_verifier") == { "grant_type" => "authorization_code", "client_id" => "client-test",
        "client_secret" => "secret-test", "code" => "one-use-code", "redirect_uri" => youtube_callback_url } &&
        challenge == oauth.fetch("code_challenge")
    end.to_return_json(body: { token_type: "Bearer", access_token: "access-test", refresh_token: "refresh-test", scope: scopes })
  end

  def lookup_channel
    stub_request(:get, Youtube::Client::CHANNEL_URL).with(headers: { "Authorization" => "Bearer access-test" })
      .to_return_json(body: { items: [ { id: "channel-test", snippet: { title: "Chaîne autorisée" } } ] })
  end
end
