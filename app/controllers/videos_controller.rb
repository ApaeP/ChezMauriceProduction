class VideosController < ApplicationController
  before_action :find_video, only: [:update, :update_rank, :destroy, :reorder]

  def index
    @video = Video.new
    @videos = Video.all.order(:position)
    @allcategories = Category.all
  end

  def reorder
    @video.insert_at(params[:position].to_i)
    head :ok
  end

  def create
    if user_signed_in?
      @video = Video.new(video_params)
      if @video.save
        respond_to do |format|
          format.js
          format.html { redirect_to realisations_path }
        end
      else
        flash[:alert] = "Vous ne pouvez pas créer de vidéo"
      end
    end
  end

  def update
    if user_signed_in?
      @video.update(video_params)
      if @video.save
        redirect_to realisations_path
      end
    end
  end

  def destroy
    if user_signed_in?
      if @video.destroy
        flash.now[:success] = 'Video was deleted'
      else
        flash.now[:success] = 'Video could not be deleted'
      end
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def find_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo, category_ids: [])
  end
end
