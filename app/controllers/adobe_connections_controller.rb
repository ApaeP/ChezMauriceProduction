class AdobeConnectionsController < OwnerConnectionsController
  PROVIDER = "adobe"
  PROVIDER_LABEL = "Adobe"
  CONNECTION_LABEL = "Frame.io"

  def select_account
    submitted = request.request_parameters
    Adobe::Authorization.new.select_account!(account_id: submitted["account_id"],
      selection_id: submitted["selection_id"], invitation: @invitation)
    redirect_to frame_io_connection_path, status: :see_other, notice: "Le compte Frame.io est connecté."
  end

  private
    def current_connection
      FrameIoConnection.current
    end

    def authorization
      Adobe::Authorization.new(redirect_uri: frame_io_callback_url)
    end

    def authorization_url(oauth, state, _challenge)
      oauth.url(state: state)
    end

    def finish_authorization(code, _attempt)
      if authorization.connect!(code: code, invitation: @invitation) == :choose_account
        "Choisissez le compte Frame.io à utiliser."
      else
        "Le compte Frame.io est connecté."
      end
    end
end
