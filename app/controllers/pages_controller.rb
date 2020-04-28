class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @contact = Contact.new
    @video = Video.new
    @videos = Video.all

    # vimeo = VimeoMe2::VimeoObject.new(ENV['VIMEO_ACCESS_TOKEN'])
    # @vimeo_video = VimeoMe2::Video.new(ENV['VIMEO_ACCESS_TOKEN'], '380593500')
    # @vimeo_video_html = @vimeo_video.video["embed"]["html"]
  end
end
