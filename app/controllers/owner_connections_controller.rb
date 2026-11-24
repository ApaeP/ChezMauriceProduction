class OwnerConnectionsController < ApplicationController
  before_action :private_response
  before_action :require_invitation, except: %i[show unlock landing]
  rescue_from MediaApi::Error, with: :connection_error
  helper_method :provider_label, :connection_label

  def show
    @invitation = active_invitation
    @connection = current_connection if @invitation
  end

  def unlock
    invitation = OwnerInvitation.redeem(request.request_parameters["invitation_code"], provider: self.class::PROVIDER)
    if invitation
      active_invitation&.destroy!
      session[invitation_key] = invitation.id
      redirect_to({ action: :show }, status: :see_other)
    else
      @error = "Ce code est invalide, expiré ou a déjà été utilisé."
      render :show, status: :unprocessable_content
    end
  end

  def authorize
    oauth = authorization
    state, challenge = @invitation.start_authorization!
    redirect_to authorization_url(oauth, state, challenge), allow_other_host: true, status: :see_other
  end

  # A redirect before the browser clears its fragment could carry the response
  # to another URL, even if this owner's session has expired.
  def landing
    response.headers["Content-Security-Policy"] = "default-src 'none'; script-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"
    render layout: false, status: request.query_string.empty? ? :ok : :bad_request
  end

  def callback
    return head :bad_request if request.query_string.present?

    submitted = request.request_parameters
    attempt = @invitation.consume_authorization(submitted["state"])
    unless attempt
      return redirect_to({ action: :show }, status: :see_other, alert: "Cette demande de connexion a expiré ou n’a pas été initiée ici.")
    end
    if submitted["error"].present? || !submitted["code"].is_a?(String) || submitted["code"].blank?
      return redirect_to({ action: :show }, status: :see_other, alert: "Autorisation #{provider_label} interrompue.")
    end

    message = finish_authorization(submitted["code"], attempt)
    redirect_to({ action: :show }, status: :see_other, notice: message)
  end

  def close
    @invitation.destroy!
    session.delete(invitation_key)
    redirect_to({ action: :show }, status: :see_other)
  end

  private
    def provider_label
      self.class::PROVIDER_LABEL
    end

    def connection_label
      self.class::CONNECTION_LABEL
    end

    def invitation_key
      "#{self.class::PROVIDER}_invitation_id"
    end

    def private_response
      no_store
      response.headers["Referrer-Policy"] = request.query_string.empty? ? "same-origin" : "no-referrer"
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
    end

    def active_invitation
      OwnerInvitation.active.where.not(redeemed_at: nil).find_by(
        id: session[invitation_key], provider: self.class::PROVIDER)
    end

    def require_invitation
      @invitation = active_invitation
      redirect_to({ action: :show }, status: :see_other, alert: "Un nouveau code de gestion est nécessaire.") unless @invitation
    end

    def connection_error(error)
      redirect_to({ action: :show }, status: :see_other, alert: error.message)
    end
end
