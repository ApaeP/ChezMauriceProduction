class ContactsController < ApplicationController

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      p "CONTACT SAVED"
    else
      p "CONTACT FORBIDDEN"
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :content, :phone)
  end
end
