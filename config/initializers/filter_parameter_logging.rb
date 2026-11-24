# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :code, :state, :verifier, :invitation, :selection_id, :session_url, :upload_url
]

Rails.application.config.filter_redirect += [ "accounts.google.com", "ims-na1.adobelogin.com" ]
