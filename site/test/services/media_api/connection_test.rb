require "test_helper"
require "webmock/minitest"

class MediaApi::ConnectionTest < ActiveSupport::TestCase
  setup do
    @endpoint = "https://auth.example.test/token"
    @url = "https://api.example.test/resource"
    @token = MediaApi::Token.new(endpoint: @endpoint, parameters: { client_secret: "example-secret" })
    @client = MediaApi::Connection.new(hosts: [ "api.example.test" ], token: @token)
  end

  test "un GET refusé renouvelle une fois le jeton et les inspections préservent les secrets" do
    stub_request(:post, @endpoint).to_return(*%w[first-token second-token].map { |token|
      { body: { access_token: token, token_type: "bearer", expires_in: 3600 }.to_json }
    })
    stub_request(:get, @url).with(headers: { "Authorization" => "Bearer first-token" }).to_return(status: 401)
    stub_request(:get, @url).with(headers: { "Authorization" => "Bearer second-token" }).to_return(body: '{"private":"secret"}')
    response = @client.request(:get, @url)
    assert_equal({ "private" => "secret" }, response.json)
    assert_equal "second-token", @token.value
    assert_requested :post, @endpoint, times: 2
    refute_match(/secret|first-token|second-token/, [ @client, @token, response ].inspect)
  end

  test "un POST refusé ne recommence pas et le corps de l’erreur reste privé" do
    stub_request(:post, @endpoint).to_return(body: { access_token: "token", token_type: "Bearer", expires_in: 3600 }.to_json)
    stub_request(:post, @url).to_return(status: 401, body: "secret")
    error = assert_raises(MediaApi::HttpError) { @client.request(:post, @url) }
    assert_equal 401, error.status
    refute_includes error.message, "secret"
    assert_requested :post, @url, times: 1
  end

  test "les hôtes et protocoles inattendus sont refusés avant de lire le jeton" do
    %w[http://api.example.test/x https://other.example.test/x https://name@api.example.test/x https://api.example.test:444/x].each do |url|
      assert_raises(MediaApi::Error) { @client.request(:get, url) }
    end
    assert_not_requested :post, @endpoint
  end
end
