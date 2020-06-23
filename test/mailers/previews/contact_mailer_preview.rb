# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def mail_to_client
    # @contact = Contact.new
    @contact = Contact.new(name: 'Robert Bite', email: 'robertbite@test.com', content: 'Bonjour, belle bite, le bout est à un coup de bagnole.')
    ContactMailer.with(contact: @contact).mail_to_client
  end

  def mail_to_prod
    # @contact = Contact.new
    @contact = Contact.new(name: 'Robert Bite', email: 'robertbite@test.com', content: 'Bonjour, belle bite, le bout est à un coup de bagnole.')
    ContactMailer.with(contact: @contact).mail_to_prod
  end
end
