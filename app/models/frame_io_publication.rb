class FrameIoPublication < ApplicationRecord
  PROJECT_ID = "53d90e32-935b-45e7-b693-5702318d606d"
  CHANNEL_ID = "UCnuO-797M605z7yuAjaitpg"

  belongs_to :realisation
  encrypts :session_url

  def self.enabled?
    ENV["FRAME_IO_PRIVATE_TRIAL"] == "1"
  end

  # Draft and export identity are committed together. A repeated notification
  # addresses the same destination file, even when it has a different event type.
  def self.prepare!(identity, source)
    find_or_create_by!(identity) do |publication|
      publication.realisation = Realisation.new(title: source.title, description: source.description, published: false)
    end
  end

  def processing?
    state.in?(%w[pending uploading])
  end

  def review!(reason)
    update!(state: "review", review_reason: reason)
  end
end
