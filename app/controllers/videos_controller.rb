class VideosController < ApplicationController
  before_action :find_video, only: [:update, :update_rank, :destroy]

  def index
    @video = Video.new
    # if params[:search].present? && params[:search][:cat] != "all"
    #   @videos = Category.find_by(name: params[:search][:cat]).videos.order(:number)
    #   # association_objects_ids = Category.find_by(name: params[:search][:cat]).video_categories.pluck(:id)
    #   # videos_array = []
    #   # association_objects_ids.each do |id|
    #   #   videos_array << VideoCategory.find(id).video
    #   # end

    #   # video_numbers_array = []
    #   # videos_array.each do |selected_vid|
    #   #   video_numbers_array << selected_vid.number
    #   # end

    #   # @videos = videos_array.sort_by.with_index{|_,i| video_numbers_array[i]}
    # else
    #   @categories = Category.all
    @videos = Video.all.order(:number)
    # end
    @allcategories = Category.all
  end

  def create
    if user_signed_in? && current_user.email == 'corbierpa@gmail.com'
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
    if user_signed_in? && current_user.email == 'corbierpa@gmail.com'
      @video.update(video_params)

      if @video.save
        respond_to do |format|
          format.html { redirect_to realisations_path }
          # format.js
        end
      else
        respond_to do |format|
          format.html { redirect_to realisations_path }
          # format.js
        end
      end


    end
  end

  def update_rank
    if user_signed_in? && current_user.email == 'corbierpa@gmail.com'
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
  end

  def destroy
    if user_signed_in? && current_user.email == 'corbierpa@gmail.com'
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
  end

  private

  def find_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:name, :title, :url, :description, :photo, category_ids: [])
  end
end

  # <!-- <button id="coroporate-btn">CORPORATE</button> -->
  # <%#= simple_form_for :search, url: realisations_path, method: "GET", remote: true, html: { id: 'search-form' } do |f| %>
  #   <%#= f.input :cat, as: :check_boxes, collection: @categories  %>
  #   <%#= f.submit "rechercher", class: "btn btn-primary" %>
  # <%# end %>
  # <!-- Parameters: {"search"=>{"categories"=>["", "1"]}, "commit"=>"Search"} -->

  # <%#= form_tag realisations_path, method: :get, remote: true, id: 'search-form' do %>
  #   <%#= radio_button :search, :cat, "all", id: "all-radio-btn", class: 'search-radio-btns' %>
  #   <%#= label :search, "Toutes", class: 'search-labels', data: { cat: "all"} %>
  #   <%# @allcategories.each do |cat| %>
  #     <%#= radio_button :search, :cat, cat.name, id: "#{cat.name.downcase.first(4)}-radio-btn", class: 'search-radio-btns' %>
  #     <%#= label :search, cat.name, class: 'search-labels', data: { cat: "#{cat.name.downcase.first(4)}"} %>
  #   <%# end %>

  #   <%#= submit_tag "rechercher", class: "btn btn-primary", id: 'search-button' %>
  # <%# end -%>
  # <!-- Parameters: {"search"=>{"cat"=>["Corporate"]}, "commit"=>"rechercher"} -->
