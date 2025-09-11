class ContactsController < ApplicationController
  def create
    if params[:contact][:website].present?
      Rails.logger.info "Spam détecté via honeypot pour #{params[:contact][:email]}"
      head :ok
      return
    end

    @contact = Contact.new(contact_params)

    respond_to do |format|
      if @contact.save
        format.turbo_stream { render turbo_stream: turbo_stream.update("contact-form", partial: "contacts/success") }
        format.html { redirect_to contact_path, notice: 'Message envoyé!' }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("contact-form", partial: "contacts/form") }
        format.html { render 'pages/contact' }
      end
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :content, :website)
  end
end
