class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # before_action :first_time_visit, unless: -> { cookies[:first_visit] }
  # before_action :authenticate_user!
  # before_action :cors_set_access_control_headers

  # # For all responses in this controller, return the CORS access control headers.

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  # # If this is a preflight OPTIONS request, then short-circuit the
  # # request, return only the necessary headers and return an empty
  # # text/plain.

  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, PUT, GET, OPTIONS'
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
      render :text => '', :content_type => 'text/plain'
    end
  end
  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

  # def first_time_visit
  #    cookies.permanent[:first_visit] = 1
  #    @first_visit = true
  # end
end

