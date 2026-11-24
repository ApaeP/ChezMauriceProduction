require "test_helper"

class MediaApi::FrameIoInventoryTest < ActiveSupport::TestCase
  HOST = "https://api.frame.io"
  ACCOUNT = "/v4/accounts/studio"
  ROOT = "#{ACCOUNT}/folders/root/children"

  setup do
    token = Struct.new(:value).new("test-inventory-access")
    api = MediaApi::Connection.new(hosts: [ "api.frame.io" ], token: token)
    @client = MediaApi::FrameIo.new(account_id: "studio", api: api, media: nil)
    @bearer = { "Authorization" => "Bearer test-inventory-access" }
    stub_project
  end

  test "recense une fois les fichiers des dossiers et de toutes les pages de la pile sans télécharger leurs originaux" do
    next_root = "#{ROOT}?after=r%2F8%3D"
    stack = "#{ACCOUNT}/version_stacks/stack/children"
    next_stack = "#{stack}?after=s2"
    list(ROOT, [ asset("folder", "nested"), asset("file", "one") ], next_path: next_root)
    list(next_root, [ asset("file", "one") ])
    list("#{ACCOUNT}/folders/nested/children", [ asset("version_stack", "stack") ])
    list(stack, [ asset("file", "two") ], next_path: next_stack)
    list(next_stack, [ asset("file", "three") ])

    assert_equal %w[one three two], @client.project_file_ids("publication").sort
    assert_not_requested :get, %r{/files/}
    assert_not_requested :get, %r{[?&]include=}
  end

  test "renvoie un inventaire vide si le dossier racine est vide et échoue si un dossier est illisible" do
    list(ROOT, [])
    assert_empty @client.project_file_ids("publication")
    list(ROOT, [ asset("file", "one"), asset("folder", "restricted") ])
    stub_request(:get, "#{HOST}#{ACCOUNT}/folders/restricted/children").to_return(status: 403)
    error = assert_raises(MediaApi::HttpError) { @client.project_file_ids("publication") }
    assert_equal 403, error.status
  end

  test "refuse les pages étrangères, cycliques, filtrées ou qui demandent une extension média" do
    [ "https://other.example#{ROOT}", "#{ACCOUNT}/folders/another/children?after=1", ROOT,
      "#{ROOT}?after=a&include=media_links.original", "#{ROOT}?after=b&type=folder", false ].each do |next_path|
      list(ROOT, [ asset("file", "one") ], next_path: next_path)
      assert_raises(MediaApi::Error) { @client.project_file_ids("publication") }
    end
    assert_requested :get, "#{HOST}#{ROOT}", times: 6
    assert_not_requested :get, %r{https://other\.example/}
  end

  test "abandonne les identités incohérentes ou les types inconnus au lieu de retourner un inventaire partiel" do
    [ asset("folder", "other").merge(project_id: "another"), asset("future-type", "new"),
      asset("folder", "../other"), asset("file", nil) ].each do |unexpected|
      list(ROOT, [ asset("file", "one"), unexpected ])
      assert_raises(MediaApi::Error) { @client.project_file_ids("publication") }
    end
    stub_project(id: "another-project")
    assert_raises(MediaApi::Error) { @client.project_file_ids("publication") }
    assert_requested :get, "#{HOST}#{ROOT}", times: 4
  end

  private
    def stub_project(id: "publication")
      stub_request(:get, "#{HOST}#{ACCOUNT}/projects/publication").with(headers: @bearer)
        .to_return(body: { data: { id: id, root_folder_id: "root" } }.to_json)
    end

    def asset(type, id)
      { type: type, id: id, project_id: "publication" }
    end

    def list(path, assets, next_path: nil)
      stub_request(:get, "#{HOST}#{path}").with(headers: @bearer)
        .to_return(body: { data: assets, links: { next: next_path } }.to_json)
    end
end
