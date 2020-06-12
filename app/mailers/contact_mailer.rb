class ContactMailer < ApplicationMailer
  def mail_to_client
    # @contact = Contact.new
    @contact = params[:contact]
    email_with_name = %("#{@contact.name}" <#{@contact.email}>)
    sender_with_name = %("Chez Maurice Production | Contact" <#{ENV['CONTACT_EMAIL']}>)
    mail(to: email_with_name, from: sender_with_name, subject: 'Chez Maurice Production | Votre demande de contact')
  end

  def mail_to_prod
    # @contact = Contact.new
    @contact = params[:contact]
    email_with_name = "Pierre-Alexandre <#{ENV['OWNER_EMAIL']}>"
    sender_with_name = %("Chez Maurice Production | Contact" <#{ENV['CONTACT_EMAIL']}>)
    mail(to: email_with_name, from: sender_with_name, subject: "Chez Maurice Production | Demande de contact de la part de #{@contact.name} (n°#{@contact.id})")
  end
end
