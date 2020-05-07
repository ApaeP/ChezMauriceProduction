class VideosController < ApplicationController
  before_action :find_video, only: [:update, :update_rank, :destroy]

  def index
    @video = Video.new
    if params[:search].present? && params[:search][:cat] != "all"
      @videos = Category.find_by(name: params[:search][:cat]).videos.order(:number)
      # association_objects_ids = Category.find_by(name: params[:search][:cat]).video_categories.pluck(:id)
      # videos_array = []
      # association_objects_ids.each do |id|
      #   videos_array << VideoCategory.find(id).video
      # end

      # video_numbers_array = []
      # videos_array.each do |selected_vid|
      #   video_numbers_array << selected_vid.number
      # end

      # @videos = videos_array.sort_by.with_index{|_,i| video_numbers_array[i]}
    else
      @categories = Category.all
      @videos = Video.all.order(:number)
    end
    @allcategories = Category.all
  end

  def create
    @video = Video.new(video_params)
    if @video.save
      redirect_to realisations_path
    else

    end
  end

  def update
    @video.update(video_params)
    if @video.save!
      redirect_to realisations_path
    else
      format.js
    end
  end

  def update_rank
    # Choper les vidéos dans l'ordre
    @videos = Video.all.order(:number)
    # L'index de l'objet que l'on veut modifier
    oldIndex = params[:numero][:oldIndex].to_i
    # l'index cible de l'objet que l'on veut modifier
    newIndex = params[:numero][:newIndex].to_i
    # Assigner le nouvel index a l'objet que l'on modifie
    @videos[oldIndex].update(number: newIndex + 1)
    # reorganiser les autres objets :
    # - si l'ancien index est superieur au nouvel index (si l'on remonte l'objet)
    if oldIndex > newIndex
      while oldIndex > newIndex
        @videos[newIndex].number += 1
        @videos[newIndex].save!
        newIndex += 1
      end
    # - si l'ancien index est inferieur au nouvel index (si l'on descend l'objet)
    elsif oldIndex < newIndex
      while oldIndex < newIndex
        @videos[newIndex].number -= 1
        @videos[newIndex].save!
        newIndex -=1
      end
    end
    # @videos = @videos.order(:number)
    redirect_back(fallback_location: root_path)
  end

  def destroy
    # recupérer le numero de la video
    num = @video.number
    # supprimer la video
    @video.destroy
    # mettre a jour les numeros des autres videos
    @videos = Video.all.order(:number)
    x = 1
    @videos.each do |video|
      video.update(number: x)
      x += 1
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def find_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo, category_ids: [])
  end
end
