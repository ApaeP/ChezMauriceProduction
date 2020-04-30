class VideosController < ApplicationController

  def create
    @video = Video.new(video_params)
    if @video.save!
      p "SAVAED"
    else
      p "NOT SAVED"
    end
  end

  private

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo)
  end
end
