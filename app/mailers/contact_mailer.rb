class ContactMailer < ApplicationMailer
  def mail_to_client
    # @contact = Contact.new
    @contact = params[:contact]
    mail(to: @contact.email, subject: 'Chez Maurice Production | Votre demande de contact')
  end

  def mail_to_prod
    # @contact = Contact.new
    @contact = params[:contact]
    mail(to: ENV['CONTACT_EMAIL'], subject: "Chez Maurice Production | Demande de contact de la part de #{@contact.name} (n°#{@contact.id})")
  end
end
