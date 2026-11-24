require "application_system_test_case"
require "webmock/minitest"

class YoutubeConsentTest < ApplicationSystemTestCase
  setup do
    @old_credentials = ENV.to_h.slice("YOUTUBE_CLIENT_ID", "YOUTUBE_CLIENT_SECRET")
    ENV.update("YOUTUBE_CLIENT_ID" => "client-test", "YOUTUBE_CLIENT_SECRET" => "secret-test")
    @previous_csrf = YoutubeConnectionsController.allow_forgery_protection
    YoutubeConnectionsController.allow_forgery_protection = true
    @code = OwnerInvitation.issue!(provider: "youtube")
    @invitation = OwnerInvitation.find_by!(code_digest: Digest::SHA256.hexdigest(@code))
    visit youtube_connection_path
    fill_in "Code de gestion fourni par l’exploitant", with: @code
    click_button "Continuer"
    assert_button "Autoriser avec Google"
  end

  teardown do
    ENV.delete("YOUTUBE_CLIENT_ID")
    ENV.delete("YOUTUBE_CLIENT_SECRET")
    ENV.update(@old_credentials)
    YoutubeConnectionsController.allow_forgery_protection = @previous_csrf
  end

  test "a Google fragment reaches Rails only through a CSRF-protected POST and cannot be replayed" do
    token_exchange = stub_request(:post, Youtube::Client::TOKEN_URL).with(
      body: hash_including(code: "synthetic-code", grant_type: "authorization_code")
    ).to_return_json(body: { access_token: "access", refresh_token: "renew", token_type: "Bearer",
      scope: Youtube::Authorization::SCOPES.join(" ") })
    stub_request(:get, Youtube::Client::CHANNEL_URL).to_return_json(body: { items: [ { id: "channel", snippet: { title: "Chaîne simulée" } } ] })
    state, = @invitation.start_authorization!
    fragment_url = "#{youtube_callback_path}#code=synthetic-code&state=#{state}"

    requests = []
    observer = lambda do |event|
      request = event.payload.fetch(:request)
      if request.path == youtube_callback_path
        requests << [ request.request_method, request.query_string, request.request_parameters["authenticity_token"].present? ]
      end
    end
    ActiveSupport::Notifications.subscribed(observer, "start_processing.action_controller") do
      visit fragment_url
      assert_selector "strong", text: "Chaîne simulée"
    end
    assert_current_path youtube_connection_path
    assert_equal [ [ "GET", "", false ], [ "POST", "", true ] ], requests
    assert_equal "", page.evaluate_script("location.hash")

    # Going back restores the cleaned landing URL rather than the OAuth code.
    page.go_back
    assert_equal "", page.evaluate_script("location.hash")
    visit fragment_url
    assert_selector "[role=alert]", text: /expiré/
    assert_requested token_exchange, times: 1
  end

  test "declining the Google grant forwards only the error and never requests a token" do
    state, = @invitation.start_authorization!
    visit "#{youtube_callback_path}#error=access_denied&state=#{state}"
    assert_selector "[role=alert]", text: /interrompue/
    assert_current_path youtube_connection_path
    assert_nil YoutubeConnection.current
    assert_not_requested :post, Youtube::Client::TOKEN_URL
  end
end
