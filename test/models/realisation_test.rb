require "test_helper"

class RealisationTest < ActiveSupport::TestCase
  test "a draft can preserve incomplete historical metadata while a published film needs a title and YouTube ID" do
    draft = Realisation.create!(legacy_vimeo_url: "https://vimeo.com/123")
    assert_not_includes Realisation.published, draft
    draft.published = true
    assert_not draft.valid?
    assert draft.errors.of_kind?(:title, :blank)
    assert draft.errors.of_kind?(:youtube_id, :blank)

    draft.assign_attributes(title: "Essai technique", youtube_id: "https://vimeo.com/123")
    assert_not draft.valid?
    draft.update!(youtube_id: "aBc123_X-yZ")
    assert_includes Realisation.published, draft
  end

  test "catalogue ordering is deterministic with duplicate or missing legacy positions" do
    last = Realisation.create!
    first = Realisation.create!(position: 1)
    second = Realisation.create!(position: 1)
    assert_equal [ first, second, last ], Realisation.where(id: [ last, first, second ]).ordered.to_a
  end
end
