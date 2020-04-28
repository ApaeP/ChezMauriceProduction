class VimeovideosController < ApplicationController
  vimeo = VimeoMe2::VimeoObject.new(ENV['VIMEO_ACCESS_TOKEN'])
    # @vimeo_video = VimeoMe2::Video.new(ENV['VIMEO_ACCESS_TOKEN'], '380593500')
    # @vimeo_video_html = @vimeo_video.video["embed"]["html"]
  def create
    @vimeovideo = VimeoMe2::Video.new(ENV['VIMEO_ACCESS_TOKEN'], video_params)
    if @video.save!
      p "\n \n \n SAVED\n \n \n "
    else
      p "\n \n \n NOT SAVED \n \n \n"
    end
  end

  private

  def video_params
    params.require(:vimeovideo).permit(:url)
  end
end
