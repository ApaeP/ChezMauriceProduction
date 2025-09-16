class Video < ApplicationRecord
  acts_as_list

  has_one_attached :photo

  has_many :video_categories, dependent: :destroy
  has_many :categories, through: :video_categories

  validates :url, presence: true, uniqueness: true

  has_vimeo_video :url, message: "Seulement les liens de videos Vimeo sont acceptés"
end
