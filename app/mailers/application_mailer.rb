class ApplicationMailer < ActionMailer::Base
  default from: ENV['DEV_MAIL']
  layout 'mailer'

end
