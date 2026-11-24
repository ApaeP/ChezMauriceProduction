class YoutubeConnectionsController < OwnerConnectionsController
  PROVIDER = "youtube"
  PROVIDER_LABEL = "Google"
  CONNECTION_LABEL = "YouTube"

  private
    def current_connection
      YoutubeConnection.current
    end

    def authorization
      Youtube::Authorization.new(redirect_uri: youtube_callback_url)
    end

    def authorization_url(oauth, state, challenge)
      oauth.url(state: state, challenge: challenge)
    end

    def finish_authorization(code, attempt)
      authorization.connect!(code: code, verifier: attempt.fetch(:verifier), invitation: @invitation)
      "La chaîne YouTube est connectée."
    end
end
