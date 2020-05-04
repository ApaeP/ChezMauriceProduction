class VideosController < ApplicationController

  def create
    @video = Video.new(video_params)
    if @video.save!
      p "SAVAED"
    else
      p "NOT SAVED"
    end
  end

  def update
    @video = Video.find(params[:id])
    @video.update(video_params)
    if @video.save!
      redirect_back(fallback_location: root_path)
    else
      p "NOT SAVED"
    end
  end

  def destroy
    @video = Video.find(params[:id])
    @video.destroy
    redirect_back(fallback_location: root_path)
  end

  private

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo)
  end
end
