class FrameIoConnection < ApplicationRecord
  encrypts :access_token, :refresh_token

  def self.current
    find_by(id: 1)
  end

  # This file lives on the same persistent local volume as SQLite. Hold it
  # across the IMS exchange so workers can't spend the same refresh token twice.
  # SQLite stays available to other writers during the network round trip.
  def self.synchronize
    File.open(Rails.root.join("storage/frame-io-oauth.lock"), File::RDWR | File::CREAT, 0o600) do |lock|
      lock.flock(File::LOCK_EX)
      yield
    end
  end

  def reconnect_required?
    refresh_token.blank?
  end
end
