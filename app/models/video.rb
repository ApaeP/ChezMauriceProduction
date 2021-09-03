class Video < ApplicationRecord
  acts_as_list
  has_one_attached :photo
  has_many :video_categories, dependent: :destroy
  has_many :categories, through: :video_categories

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true

  # Gemify has_vimeo
  has_vimeo_video :url, message: "Seulement les liens de videos Vimeo sont acceptés"

  after_validation :downcase_and_delete_special_chars

  def downcase_and_delete_special_chars
    self.name = self.name.downcase.gsub(/[^0-9A-Za-z]/, '')
  end

end
