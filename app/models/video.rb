class Video < ApplicationRecord
  include PgSearch::Model

  has_one_attached :photo

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true#, format: { with: ( /\Ahttps\:\/\/vimeo\.com\/\d{9}\z/ || /\Ahttps\:\/\/.{3}\.vimeo\.com\/\d{9}\z/ || /\Avimeo\.com\/\d{9}\z/ || /\A.{3}\.vimeo\.com\/\d{9}\z/ ), message: ": Le lien n'est pas correct"}

  # Gemify has_vimeo
  has_vimeo_video :url, message: "Seulement les liens de videos Vimeo sont acceptés"

  acts_as_taggable_on :category

  pg_search_scope :global_search,
  against: [:category],
  using: { tsearch: { any_word: true } }

  $categories = ['Corporate', 'Publicité']

  after_validation :downcase_and_delete_special_chars

  def downcase_and_delete_special_chars
    self.name = self.name.downcase.gsub(/[^0-9A-Za-z]/, '')
  end

end
