require "test_helper"
require "tmpdir"
require "base64"

class LegacyCatalogueTest < ActiveSupport::TestCase
  setup do
    @directory = Pathname.new(Dir.mktmpdir)
    @directory.join("originals").mkdir
    @manifest = @directory.join("catalogue.json")
    @original = @directory.join("originals", "42")
    @original.binwrite(Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jYhcAAAAASUVORK5CYII="))
    @video = { id: 42, title: "Film technique", description: "Description", position: 7,
      categories: [ "Interview", "Produit" ], vimeo_url: "https://vimeo.com/123",
      thumbnail: { key: "ancienne-cle", file: "42", filename: "vignette.png", byte_size: @original.size,
        checksum: Digest::MD5.file(@original).base64digest } }
  end

  teardown { FileUtils.remove_entry(@directory) }

  test "reimport updates historical metadata while preserving publication, associations and unchanged thumbnail bytes" do
    import(@video)
    record = Realisation.find_by!(legacy_id: 42)
    assert_not record.published?
    assert_nil record.youtube_id
    assert_equal 7, record.position
    assert_equal "https://vimeo.com/123", record.legacy_vimeo_url
    assert_equal %w[Interview Produit], record.categories.order(:name).pluck(:name)
    assert_equal @original.binread, record.thumbnail.download
    first_blob = record.thumbnail.blob
    record.update!(published: true, published_at: Time.utc(2020, 1, 1), youtube_id: "aBc123_X-yZ")

    assert_no_difference [ "Realisation.count", "ActiveStorage::Blob.count" ] do
      import(@video.merge(title: "Titre actualisé", position: 2, categories: [ "Produit" ]))
    end
    assert_equal "Titre actualisé", record.reload.title
    assert_equal 2, record.position
    assert_equal [ "Produit" ], record.categories.pluck(:name)
    assert_equal first_blob, record.thumbnail.blob
    assert record.published?
    assert_equal Time.utc(2020, 1, 1), record.published_at
    assert_equal "aBc123_X-yZ", record.youtube_id

    import(@video.merge(thumbnail: nil))
    assert_not record.reload.thumbnail.attached?
  end

  test "missing or corrupted originals do not create a partial record" do
    @original.binwrite("corrupt")
    assert_match(/ne correspond pas/, assert_raises(RuntimeError) { import(@video) }.message)
    @original.delete
    assert_match(/ancienne-cle/, assert_raises(RuntimeError) { import(@video) }.message)
    assert_nil Realisation.find_by(legacy_id: 42)
  end

  test "duplicate source identifiers fail before any import" do
    assert_raises(ArgumentError) { import(@video, @video) }
    assert_nil Realisation.find_by(legacy_id: 42)
  end

  test "identifiers are scoped to the owning catalogue and preserve textual Next.js identifiers" do
    import(@video)
    import(@video.merge(id: "42", title: "Autre film"), source: "nextjs")
    import(@video.merge(id: "asset/A-version-02"), source: "nextjs")
    assert_equal "Film technique", Realisation.find_by!(legacy_source: "rails", legacy_id: "42").title
    assert_equal "Autre film", Realisation.find_by!(legacy_source: "nextjs", legacy_id: "42").title
    assert Realisation.exists?(legacy_source: "nextjs", legacy_id: "asset/A-version-02")
  end

  private
    def import(*videos, source: "rails")
      @manifest.write(JSON.generate(version: 1, source: source, videos: videos))
      LegacyCatalogue.new(@manifest).import!
    end
end
