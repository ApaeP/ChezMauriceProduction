class Category < ApplicationRecord
  has_many :video_categories
  has_many :videos, through: :videos
end
