class AddPositionToVideos < ActiveRecord::Migration[6.0]
  def change
    add_column :videos, :position, :integer
    set_position
  end

  def set_position
    Video.all.each { |video| video.update(position: video.number) }
  end
end
