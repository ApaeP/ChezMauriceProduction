require "test_helper"

class MediaApi::FrameIoAccountsTest < ActiveSupport::TestCase
  URL = "https://api.frame.io/v4/accounts"

  test "les comptes sélectionnables proviennent de toutes les pages Adobe" do
    next_path = "/v4/accounts?after=a%2Fb%3D"
    studio = { id: "studio", display_name: "Studio" }
    stub_request(:get, URL).with(headers: { "Authorization" => "Bearer test-access" })
      .to_return(body: { data: [ studio ], links: { next: next_path } }.to_json)
    stub_request(:get, "https://api.frame.io#{next_path}").with(headers: { "Authorization" => "Bearer test-access" })
      .to_return(body: { data: [ studio, { id: "second", display_name: "Autre studio" } ], links: { next: nil } }.to_json)

    assert_equal [ { id: "studio", name: "Studio" }, { id: "second", name: "Autre studio" } ],
      MediaApi::FrameIo.accounts_for(access_token: "test-access")
  end

  test "aucun compte disponible produit une liste vide" do
    stub_request(:get, URL).to_return(body: { data: [], links: { next: nil } }.to_json)
    assert_empty MediaApi::FrameIo.accounts_for(access_token: "test-access")
  end

  test "une pagination étrangère ou cyclique échoue avant tout nouveau transfert du jeton" do
    [ "https://example.org/v4/accounts", "/v4/me", "/v4/accounts" ].each do |path|
      stub_request(:get, URL).to_return(body: { data: [], links: { next: path } }.to_json)
      assert_raises(MediaApi::Error) { MediaApi::FrameIo.accounts_for(access_token: "test-access") }
    end
    assert_requested :get, URL, times: 3
    assert_not_requested :get, "https://example.org/v4/accounts"
  end
end
