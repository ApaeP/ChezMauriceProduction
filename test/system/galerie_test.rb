require "application_system_test_case"

class GalerieTest < ApplicationSystemTestCase
  setup do
    @category = Category.create!(name: "Documentaire")
    10.times do |i|
      film = Realisation.create!(title: "Essai de navigation #{i}", position: i + 1, youtube_id: "test_______", published: true)
      film.categories << @category
      @film = film
    end
  end

  test "frame history restores the filter, scroll and focus on close and browser back" do
    visit realisations_path
    click_link @category.name
    gallery_path = realisations_path(categorie: @category.id)
    assert_current_path gallery_path
    link = find_link(@film.title, exact: false)
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", link)
    position = page.evaluate_script("window.scrollY")
    assert_operator position, :>, 0
    link.click
    assert_modal
    find("button[aria-label='Fermer la fiche']").click
    assert_gallery_restored(gallery_path, position)

    page.go_forward
    assert_modal
    page.go_back
    assert_gallery_restored(gallery_path, position)

    find_link(@film.title, exact: false).click
    assert_modal
    find("dialog").send_keys(:escape)
    assert_gallery_restored(gallery_path, position)
  end

  test "refresh on an open modal serves a standalone detail page" do
    visit realisations_path
    find_link(@film.title, exact: false).click
    assert_modal
    page.refresh
    assert_selector "article h1", text: @film.title
    assert_no_selector "dialog"
    assert_link "Toutes les réalisations", href: realisations_path
  end

  private

  def assert_modal
    assert_current_path realisation_path(@film)
    assert_selector "turbo-frame#film_details dialog:modal h1", text: @film.title
    assert_selector "dialog button:focus"
    assert_title "#{@film.title} · Chez Maurice Production"
    assert_selector "head link[rel='canonical'][href$='#{realisation_path(@film)}']", visible: :all
    assert_no_selector "meta[name=robots]", visible: :all
  end

  def assert_gallery_restored(path, position)
    assert_current_path path
    assert_selector ".category-list [aria-current=page]", text: @category.name
    assert_no_selector "dialog"
    assert_selector "a:focus", text: @film.title
    assert_in_delta position, page.evaluate_script("window.scrollY"), 2
  end
end
