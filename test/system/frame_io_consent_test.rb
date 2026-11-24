require "application_system_test_case"
require "webmock/minitest"

class FrameIoConsentTest < ApplicationSystemTestCase
  test "the owner selects a verified Frame.io account after returning to the browser" do
    credentials = { "FRAME_IO_AUTH_MODE" => "user", "ADOBE_WEB_CLIENT_ID" => "client-test",
      "ADOBE_WEB_CLIENT_SECRET" => "secret-test", "ADOBE_WEB_SCOPES" => "frameio" }
    original = ENV.to_h.slice(*credentials.keys)
    previous_csrf = AdobeConnectionsController.allow_forgery_protection
    ENV.update(credentials)
    AdobeConnectionsController.allow_forgery_protection = true
    code = OwnerInvitation.issue!(provider: "adobe")
    visit frame_io_connection_path
    fill_in "Code de gestion fourni par l’exploitant", with: code
    click_button "Continuer"
    assert_button "Autoriser avec Adobe"
    state, = OwnerInvitation.find_by!(code_digest: Digest::SHA256.hexdigest(code)).start_authorization!
    stub_request(:post, MediaApi::FrameIo::TOKEN_URL).to_return_json(body: {
      token_type: "bearer", access_token: "fake-access", refresh_token: "fake-refresh", expires_in: 3600 })
    stub_request(:get, "https://api.frame.io/v4/accounts").to_return_json(body: {
      data: [ { id: "first", display_name: "Studio" }, { id: "second", display_name: "Atelier" } ], links: {} })

    visit "#{frame_io_callback_path}#code=simulated&state=#{state}"
    assert_current_path frame_io_connection_path
    assert_select "Compte Frame.io à utiliser", options: [ "Sélectionnez un compte", "Studio (first)", "Atelier (second)" ]
    assert_nil FrameIoConnection.current
    select "Atelier (second)", from: "Compte Frame.io à utiliser"
    click_button "Connecter ce compte"
    assert_selector "strong", text: "Atelier"
    assert_text "(second)"
    assert_no_selector "select"
    assert_equal "second", FrameIoConnection.current.account_id
  ensure
    AdobeConnectionsController.allow_forgery_protection = previous_csrf
    credentials.each_key { |key| ENV.delete(key) }
    ENV.update(original)
  end
end
