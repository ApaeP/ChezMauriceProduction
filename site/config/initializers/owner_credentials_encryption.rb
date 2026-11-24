# Credentials under active_record_encryption are also supported natively by Rails.
{ primary_key: "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", key_derivation_salt: "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" }.each do |key, variable|
  value = ENV[variable].presence
  if value.nil? && Rails.env.local?
    value = Rails.application.key_generator.generate_key("chez-maurice/#{key}", 32).unpack1("H*")
  end
  Rails.application.config.active_record.encryption.public_send("#{key}=", value) if value
end
