class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @contact = Contact.new
    @video = Video.new
    # @videos = Video.all.order(:number)
    if params["search"]
      @filter = params["search"]["category"].flatten.reject(&:blank?)
      @videos = Video.all.order(:number).global_search("#{@filter}")
    else
      @videos = Video.all.order(:number)
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def legal

  end

end
