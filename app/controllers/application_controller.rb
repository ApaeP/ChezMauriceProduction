class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :first_time_visit, unless: -> { cookies[:first_visit] }
  # before_action :authenticate_user!
  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

  def first_time_visit
     cookies.permanent[:first_visit] = 1
     @first_visit = true
  end
end

# class ApplicationController < ActionController::Base
#   protect_from_forgery with: :exception
# end
