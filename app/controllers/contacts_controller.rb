class ContactsController < ApplicationController

  def create
    @contact = Contact.new(contact_params)
    if @contact.save

    else

    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :content, :phone, :company, :known_from)
  end
end
