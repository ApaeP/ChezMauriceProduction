class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @contact = Contact.new
  end

  def gallery
  end

  def contact
  end
end
