class Contact < ApplicationRecord
  validates :email, presence: true, format: { with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i }
  validates :content, presence: true
  validates :name, presence: true

  after_create :send_emails

  private

  def send_emails
    ContactMailer.with(contact: self).mail_to_client.deliver_later
    ContactMailer.with(contact: self).mail_to_prod.deliver_later
  end
end
