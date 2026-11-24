module RealisationsHelper
  def youtube_embed_url(film)
    "https://www.youtube-nocookie.com/embed/#{film.youtube_id}"
  end

  def video_structured_data(film)
    return unless film.published_at && film.description.present? && film.thumbnail.attached? && film.thumbnail.image?

    {
      "@context" => "https://schema.org",
      "@type" => "VideoObject",
      name: film.title,
      description: film.description,
      embedUrl: youtube_embed_url(film),
      thumbnailUrl: rails_storage_proxy_url(film.thumbnail),
      uploadDate: film.published_at.iso8601
    }
  end
end
