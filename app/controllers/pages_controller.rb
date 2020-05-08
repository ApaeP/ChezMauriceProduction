class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

  def home
  end

  def legal
  end

  def contact
    @contact = Contact.new
  end

  # def infos
  # end

end
