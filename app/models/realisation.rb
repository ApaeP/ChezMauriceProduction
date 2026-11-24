class Realisation < ApplicationRecord
  has_and_belongs_to_many :categories
  has_one_attached :thumbnail

  validates :title, :youtube_id, presence: true, if: :published?
  validates :youtube_id, format: { with: /\A[a-zA-Z0-9_-]{11}\z/ }, allow_nil: true
  normalizes :youtube_id, with: ->(value) { value.strip.presence }

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(arel_table[:position].asc.nulls_last, :id) }
end
