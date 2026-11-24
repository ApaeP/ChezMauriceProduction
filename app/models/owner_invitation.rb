class OwnerInvitation < ApplicationRecord
  serialize :pending_adobe_grant, coder: JSON
  encrypts :pending_adobe_grant, :pkce_verifier
  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.issue!(provider:)
    code = SecureRandom.urlsafe_base64(24)
    transaction do
      where(expires_at: ..Time.current).delete_all
      create!(provider: provider, code_digest: Digest::SHA256.hexdigest(code), expires_at: 15.minutes.from_now)
    end
    code
  end

  def self.redeem(code, provider:)
    return unless code.is_a?(String) && code.present?

    invitation = active.where(provider: provider, code_digest: Digest::SHA256.hexdigest(code))
    invitation.first if invitation.where(redeemed_at: nil).update_all(redeemed_at: Time.current) == 1
  end

  def adobe_accounts
    pending_adobe_grant&.fetch("accounts", []) || []
  end

  def start_authorization!
    state = SecureRandom.urlsafe_base64(32)
    verifier = SecureRandom.urlsafe_base64(48) if provider == "youtube"
    update!(state_digest: Digest::SHA256.hexdigest(state), state_used: false, pkce_verifier: verifier, pending_adobe_grant: nil)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) if verifier
    [ state, challenge ]
  end

  def consume_authorization(state)
    return unless state.is_a?(String) && state.present?

    digest = Digest::SHA256.hexdigest(state)
    matching = self.class.active.where(id: id, provider: provider, state_digest: digest, state_used: false)
    stored = matching.pick(:id, :pkce_verifier)
    if stored && matching.update_all(state_used: true, pkce_verifier: nil) == 1
      self.state_digest = digest
      { verifier: stored.last }
    end
  end

  # Provider calls take place outside this short transaction. A slow callback
  # cannot overwrite a new authorization or a session closed in another tab.
  def with_current_authorization
    self.class.transaction do
      current = self.class.active.lock.where.not(redeemed_at: nil).find_by(
        id: id, provider: provider, state_digest: state_digest, state_used: true)
      raise MediaApi::Error, "Cette autorisation a expiré ou a été remplacée." unless current && state_digest.present?
      yield current
    end
  end
end
