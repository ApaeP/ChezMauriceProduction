class ContactsController < ApplicationController

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      ContactMailer.with(contact: @contact).mail_to_client.deliver_later
      ContactMailer.with(contact: @contact).mail_to_prod.deliver_later
    else

    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :content, :phone, :company, :known_from)
  end
end
