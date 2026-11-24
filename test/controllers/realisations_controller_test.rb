require "test_helper"

class RealisationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Série documentaire")
    @draft_category = Category.create!(name: "Archives")
    @film = Realisation.create!(title: "Film de test A", position: 2, youtube_id: "test_______", published: true, description: "Texte <script>confidentiel</script>")
    @other = Realisation.create!(title: "Film de test B", position: 1, youtube_id: "other______", published: true)
    @draft = Realisation.create!(title: "Brouillon", position: 3)
    @film.categories << @category
    @draft.categories << @draft_category
  end

  test "gallery contains ordered shareable links and only public categories" do
    get realisations_path
    assert_response :success
    assert_select ".film-card" do |links|
      assert_equal [ realisation_path(@other), realisation_path(@film) ], links.map { |link| link["href"] }
      assert links.all? { |link| link["data-turbo-frame"] == "film_details" && link["data-turbo-action"] == "advance" }
    end
    assert_select ".category-list a", text: @draft_category.name, count: 0
    assert_select "iframe", count: 0
    assert_select "meta[name=robots]", count: 0
    assert_select "link[rel=canonical][href=?]", realisations_url

    get realisations_path(categorie: @category.id)
    assert_response :success
    assert_select ".film-card", count: 1
    assert_select ".category-list a[aria-current]", text: @category.name
    assert_select "meta[name=robots][content='noindex,follow']"
    assert_select "link[rel=canonical][href=?]", realisations_url

    get realisations_path(categorie: @draft_category.id)
    assert_response :not_found
  end

  test "a direct show has the complete indexed content and a link back to the gallery" do
    get realisation_path(@film)
    assert_response :success
    assert_select "html[lang=fr] head title", text: "#{@film.title} · Chez Maurice Production"
    assert_select "h1", text: @film.title
    assert_select "iframe[src='https://www.youtube-nocookie.com/embed/test_______']"
    assert_select "link[rel=canonical][href=?]", realisation_url(@film)
    assert_select "p.film-description", text: @film.description
    assert_select ".film-description script", count: 0
    assert_select "main a[href=?]", realisations_path
    assert_select "dialog", count: 0
    assert_select "meta[name=robots]", count: 0
    assert_select "script[type='application/ld+json']", count: 0
    assert_select "meta[property='og:url'][content=?]", realisation_url(@film)
    assert_select "meta[property='og:type'][content='video.other']"
    assert_select "meta[name='twitter:description'][content=?]", @film.description
  end

  test "a frame request returns the same film inside an accessible modal" do
    get realisation_path(@film), headers: { "Turbo-Frame" => "film_details" }
    assert_response :success
    assert_select "turbo-frame#film_details dialog[aria-labelledby='film-title']" do
      assert_select "h1#film-title", text: @film.title
      assert_select "iframe", count: 1
      assert_select "button[aria-label='Fermer la fiche']"
    end
  end

  test "structured video metadata uses the actual thumbnail and first publication date" do
    @film.update!(title: "Essai & montage", description: "Un essai </script><script>injection</script>.")
    File.open(Rails.root.join("app/assets/images/favicon.png")) do |file|
      @film.thumbnail.attach(io: file, filename: "test.png", content_type: "image/png")
    end
    get realisation_path(@film)
    assert_select "script[type='application/ld+json']", count: 0

    @film.update!(published_at: Time.iso8601("2025-05-01T09:00:00Z"))
    get realisation_path(@film)
    assert_response :success
    assert_select "head title", text: "Essai & montage · Chez Maurice Production"
    assert_select "meta[property='og:image'][content=?]", rails_storage_proxy_url(@film.thumbnail)
    assert_select "script[type='application/ld+json']", count: 1 do |scripts|
      data = JSON.parse(scripts.first.text)
      assert_equal "VideoObject", data.fetch("@type")
      assert_equal @film.title, data.fetch("name")
      assert_equal @film.description, data.fetch("description")
      assert_equal "https://www.youtube-nocookie.com/embed/test_______", data.fetch("embedUrl")
      assert_equal @film.published_at, Time.iso8601(data.fetch("uploadDate"))
      assert_equal rails_storage_proxy_url(@film.thumbnail), data.fetch("thumbnailUrl")
    end
    assert_select "script", text: "injection", count: 0

    @film.thumbnail.purge
    get realisation_path(@film)
    assert_select "script[type='application/ld+json']", count: 0
  end

  test "drafts return 404 in the standalone and frame presentations" do
    get realisation_path(@draft)
    assert_response :not_found
    get realisation_path(@draft), headers: { "Turbo-Frame" => "film_details" }
    assert_response :not_found
  end
end
