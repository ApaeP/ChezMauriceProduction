class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @contact = Contact.new
    @video = Video.new
    @videos = Video.all.order('created_at DESC')
  end
end
