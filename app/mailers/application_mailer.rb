class ApplicationMailer < ActionMailer::Base
  default from: 'chezmauriceproddev@gmail.com'
  layout 'mailer'

  def mail_to_client
    @contact = Contact.new
    @contact = params[:contact]
    mail(to: @contact.email, subject: 'Chez Maurice Production - Votre demande de contact')
  end

  def mail_to_prod
    @contact = Contact.new
    @contact = params[:contact]
    mail(to: default, subject: "n°#{@contact.id} - Contact de la part de #{@contact.name}")
  end
end
