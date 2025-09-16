class VideosController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy]
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

  def update
    @video.update(video_params)
    if @video.save
      redirect_to realisations_path
    end
  end

  def destroy
    if @video.destroy
      result = :ok
      flash[:success] = 'La vidéo a été supprimée'
    else
      result = :error
      flash[:warning] = 'La vidéo n\'a pas été supprimée'
    end
    render json: { result: result }, status: result
  end

  private

  def find_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo, category_ids: [])
  end
end
