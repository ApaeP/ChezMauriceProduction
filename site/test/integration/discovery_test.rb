require "test_helper"

class DiscoveryTest < ActionDispatch::IntegrationTest
  test "le stockage de la galerie est en lecture seule depuis le web" do
    post rails_direct_uploads_path
    assert_response :not_found
    put update_rails_disk_service_path("test")
    assert_response :not_found
  end

  test "les quatre entrées historiques du site ont un contenu et une URL canonique uniques" do
    paths = [ root_path, realisations_path, contact_path, mentions_legales_path ]
    titles = []
    descriptions = []
    paths.each do |path|
      get path
      assert_response :success
      assert_select "html[lang=fr]"
      assert_select "h1", count: 1
      assert_select "link[rel=canonical][href=?]", "http://www.example.com#{path}"
      titles << css_select("title").first.text
      descriptions << css_select('meta[name="description"]').first["content"]
    end
    assert_equal paths.size, titles.uniq.size
    assert_equal paths.size, descriptions.uniq.size

    get root_path, headers: { "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 Version/15.0 Mobile/15E148 Safari/604.1" }
    assert_response :success
    organization = JSON.parse(css_select('script[type="application/ld+json"]').first.text)
    assert_equal "Organization", organization["@type"]
    assert_equal "Chez Maurice Production", organization["name"]
    assert_select "a[href=?]", realisations_path
    assert_select "#informations"
    get contact_path
    assert_select 'a[href="tel:+33661738763"]'
    assert_select 'a[href="mailto:contact@chezmauriceproduction.com"]'
    get "/videos"
    assert_response :moved_permanently
    assert_redirected_to realisations_url
    get "/studio"
    assert_response :moved_permanently
    assert_redirected_to root_url
  end

  test "le sitemap et les robots renvoient au catalogue public" do
    film = Realisation.create!(title: "Essai sitemap", youtube_id: "sitemaptest", published: true)
    draft = Realisation.create!(title: "Brouillon")
    get sitemap_path
    assert_response :success
    assert_equal "application/xml", response.media_type
    doc = Nokogiri::XML(response.body).remove_namespaces!
    expected = [ root_url, realisations_url, contact_url, mentions_legales_url, realisation_url(film) ]
    assert_equal expected.sort, doc.xpath("//url/loc").map(&:text).sort
    refute_includes doc.xpath("//url/loc").map(&:text), realisation_url(draft)
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "Sitemap: #{sitemap_url}"
    get realisation_path(draft)
    assert_response :not_found
    get "/page-inconnue"
    assert_response :not_found
  end
end
