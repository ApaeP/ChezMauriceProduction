require "test_helper"
require "webmock/minitest"

class AdobeConnectionsControllerTest < ActionDispatch::IntegrationTest
  SETTINGS = {
    "FRAME_IO_AUTH_MODE" => "user", "ADOBE_WEB_CLIENT_ID" => "client-test",
    "ADOBE_WEB_CLIENT_SECRET" => "secret-test", "ADOBE_WEB_SCOPES" => "frameio"
  }.freeze

  setup do
    @saved = ENV.to_h.slice(*SETTINGS.keys)
    ENV.update(SETTINGS)
    https!
  end

  teardown do
    SETTINGS.each_key { |key| ENV.delete(key) }
    ENV.update(@saved)
  end

  test "an invitation and browser session are restricted to their provider" do
    adobe_code = OwnerInvitation.issue!(provider: "adobe")
    youtube_code = OwnerInvitation.issue!(provider: "youtube")
    post youtube_connection_path, params: { invitation_code: adobe_code }
    assert_response :unprocessable_content
    post frame_io_connection_path, params: { invitation_code: youtube_code }
    assert_response :unprocessable_content

    post frame_io_connection_path, params: { invitation_code: adobe_code }
    follow_redirect!
    assert_select "h1", text: "Connexion Frame.io"
    assert_select "button", text: "Autoriser avec Adobe"
    get youtube_connection_path
    assert_select "input[name='invitation_code']"
    post authorize_youtube_path
    assert_redirected_to youtube_connection_path
    post youtube_connection_path, params: { invitation_code: youtube_code }
    follow_redirect!
    assert_select "button", text: "Autoriser avec Google"

    delete frame_io_connection_path
    get frame_io_connection_path
    assert_select "input[name='invitation_code']"
    get youtube_connection_path
    assert_select "button", text: "Autoriser avec Google"
  end

  test "a single verified Frame.io account becomes active and its verified name is displayed" do
    unlock
    state = start_consent
    token = stub_accounts(%w[alpha])
    post frame_io_callback_path, params: { code: "simulated-code", state: state }
    follow_redirect!
    assert_select "strong", text: "Compte alpha"
    assert_includes response.body, "alpha"
    assert_no_match(/fake-access|fake-refresh/, response.body)
    assert_equal "alpha", FrameIoConnection.current.account_id

    post frame_io_callback_path, params: { code: "simulated-code", state: state }
    follow_redirect!
    assert_select "[role=alert]", text: /expiré/
    assert_requested token, times: 1
  end

  test "a pending multi-account choice is private, bound to the current offer and committed only on confirmation" do
    unlock
    FrameIoConnection.create!(id: 1, account_id: "old", account_name: "Précédent", generation: "initial", refresh_token: "old-token")
    state = start_consent
    stub_accounts(%w[alpha beta])
    post frame_io_callback_path, params: { code: "simulated-code", state: state }
    follow_redirect!
    assert_select "option[value=alpha]", text: "Compte alpha (alpha)"
    assert_select "option[value=beta]"
    assert_select "strong", text: "Précédent"
    selection = css_select("input[name='selection_id']").first["value"]
    assert_no_match(/fake-access|fake-refresh/, response.body)

    post frame_io_account_path, params: { account_id: "forged", selection_id: selection }
    assert_redirected_to frame_io_connection_path
    assert_equal "old", FrameIoConnection.current.account_id
    post frame_io_account_path, params: { account_id: "beta", selection_id: "expired" }
    assert_equal "old", FrameIoConnection.current.account_id

    post frame_io_account_path, params: { account_id: "beta", selection_id: selection }
    follow_redirect!
    assert_select "strong", text: "Compte beta"
    assert_select "select", count: 0
    post frame_io_account_path, params: { account_id: "alpha", selection_id: selection }
    assert_equal "beta", FrameIoConnection.current.account_id
  end

  test "a Google state cannot complete Adobe consent and declining Adobe cannot connect an account" do
    unlock
    google_code = OwnerInvitation.issue!(provider: "youtube")
    post youtube_connection_path, params: { invitation_code: google_code }
    google_state, = OwnerInvitation.find_by!(provider: "youtube").start_authorization!
    adobe_state = start_consent
    post frame_io_callback_path, params: { code: "simulated-code", state: google_state }
    follow_redirect!
    assert_select "[role=alert]", text: /expiré/
    post frame_io_callback_path, params: { error: "access_denied", state: adobe_state }
    follow_redirect!
    assert_select "[role=alert]", text: /interrompue/
    assert_nil FrameIoConnection.current
    assert_not_requested :post, MediaApi::FrameIo::TOKEN_URL
  end

  private

  def unlock
    post frame_io_connection_path, params: { invitation_code: OwnerInvitation.issue!(provider: "adobe") }
    assert_redirected_to frame_io_connection_path
  end

  def start_consent
    post authorize_frame_io_path
    assert_response :see_other
    location = URI.parse(response.location)
    assert_equal "ims-na1.adobelogin.com", location.host
    params = URI.decode_www_form(location.query).to_h
    assert_equal frame_io_callback_url, params.fetch("redirect_uri")
    assert_match(/\Ahttps:/, params.fetch("redirect_uri"))
    assert_equal "fragment", params.fetch("response_mode")
    params.fetch("state")
  end

  def stub_accounts(ids)
    token = stub_request(:post, MediaApi::FrameIo::TOKEN_URL).with(
      body: { grant_type: "authorization_code", code: "simulated-code" },
      basic_auth: [ "client-test", "secret-test" ]
    ).to_return_json(body: { token_type: "bearer", access_token: "fake-access", refresh_token: "fake-refresh", expires_in: 3600 })
    stub_request(:get, "https://api.frame.io/v4/accounts").with(headers: { "Authorization" => "Bearer fake-access" })
      .to_return_json(body: { data: ids.map { |id| { id: id, display_name: "Compte #{id}" } }, links: {} })
    token
  end
end
