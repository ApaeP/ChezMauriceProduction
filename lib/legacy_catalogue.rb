require "digest"
require "json"

class LegacyCatalogue
  def initialize(manifest)
    @manifest = Pathname.new(manifest)
  end

  def import!
    catalogue = JSON.parse(@manifest.read)
    raise ArgumentError, "Version de catalogue inconnue" unless catalogue.fetch("version") == 1
    source = catalogue.fetch("source")
    raise ArgumentError, "Source de catalogue inconnue" unless %w[rails nextjs].include?(source)

    videos = catalogue.fetch("videos")
    ids = videos.map { |video| video.fetch("id") }
    unless ids.all? { |id| (id.is_a?(String) && id.present?) || id.is_a?(Integer) } && ids.map(&:to_s).uniq.size == ids.size
      raise ArgumentError, "Chaque vidéo doit avoir un identifiant stable et unique dans sa source"
    end

    videos.each { |video| import_video!(source, video) }
    videos.size
  end

  private
    def import_video!(source, video)
      record = Realisation.find_or_initialize_by(legacy_source: source, legacy_id: video.fetch("id").to_s)
      with_thumbnail(record, video.fetch("thumbnail")) do |blob|
        Realisation.transaction do
          record.assign_attributes(
            title: video.fetch("title"), description: video.fetch("description"),
            position: video.fetch("position"), legacy_vimeo_url: video.fetch("vimeo_url")
          )
          record.categories = video.fetch("categories").map { |name| Category.find_or_create_by!(name: name) }
          record.thumbnail = blob unless record.thumbnail.blob == blob
          record.save!
        end
      end
    rescue StandardError => error
      raise "Vidéo historique #{video.fetch('id')} : #{error.message}"
    end

    def with_thumbnail(record, thumbnail)
      return yield(nil) unless thumbnail

      local_file = thumbnail.fetch("file")
      unless local_file.is_a?(String) && /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/.match?(local_file)
        raise ArgumentError, "Nom de copie locale de vignette invalide"
      end
      path = @manifest.dirname.join("originals", local_file)
      filename = thumbnail.fetch("filename")
      unless path.file?
        raise ArgumentError, "Placer l’original #{filename} (clé #{thumbnail.fetch('key')}) dans #{path}"
      end

      checksum = Digest::MD5.file(path).base64digest
      if path.size != thumbnail.fetch("byte_size") || (thumbnail.fetch("checksum") && checksum != thumbnail["checksum"])
        raise ArgumentError, "La vignette #{path} ne correspond pas à l’original exporté"
      end

      current = record.thumbnail.blob
      if current && current.checksum == checksum && current.filename.to_s == filename && current.service.exist?(current.key)
        return yield(current)
      end

      type = Marcel::MimeType.for(path)
      raise ArgumentError, "Format d’image inconnu dans #{path}" unless type.start_with?("image/")

      # Reserve the new blob before writing. The old attachment stays usable if the
      # disk upload or the subsequent catalogue transaction fails.
      blob = ActiveStorage::Blob.create_before_direct_upload!(filename: filename, byte_size: path.size,
        checksum: checksum, content_type: type)
      begin
        File.open(path, "rb") { |file| blob.upload(file) }
        blob.save!
        yield blob
      rescue StandardError
        blob.purge unless blob.attachments.exists?
        raise
      end
    end
end
