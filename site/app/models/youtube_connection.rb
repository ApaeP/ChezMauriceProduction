class YoutubeConnection < ApplicationRecord
  encrypts :refresh_token

  def self.current
    find_by(id: 1)
  end
end
