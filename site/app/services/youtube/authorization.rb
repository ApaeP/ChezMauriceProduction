module Youtube
  class Authorization
    SCOPES = %w[https://www.googleapis.com/auth/youtube.upload https://www.googleapis.com/auth/youtube.readonly].freeze
    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"

    def initialize(redirect_uri:)
      @redirect_uri = redirect_uri
      @client_id = ENV["YOUTUBE_CLIENT_ID"].presence
      @client_secret = ENV["YOUTUBE_CLIENT_SECRET"].presence
      unless @client_id && @client_secret && ActiveRecord::Encryption.config.has_primary_key? && ActiveRecord::Encryption.config.has_key_derivation_salt?
        raise MediaApi::Error, "La connexion Google sera disponible après configuration par l’exploitant."
      end
    end

    def inspect
      "#<#{self.class.name} [FILTERED]>"
    end

    def url(state:, challenge:)
      parameters = { client_id: @client_id, redirect_uri: @redirect_uri, response_type: "code", response_mode: "fragment",
        access_type: "offline", prompt: "select_account consent", scope: SCOPES.join(" "),
        state: state, code_challenge: challenge, code_challenge_method: "S256" }
      "#{AUTH_URL}?#{URI.encode_www_form(parameters)}"
    end

    def connect!(code:, verifier:, invitation:)
      raise MediaApi::Error, "Cette invitation ne donne pas accès à YouTube." unless invitation.provider == "youtube"
      response = MediaApi::Connection.new(hosts: [ "oauth2.googleapis.com" ]).request(:post, Youtube::Client::TOKEN_URL,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: URI.encode_www_form(grant_type: "authorization_code", client_id: @client_id,
          client_secret: @client_secret, code: code, code_verifier: verifier, redirect_uri: @redirect_uri)).json
      unless response.is_a?(Hash) && response["token_type"].to_s.casecmp?("bearer") &&
          response["access_token"].is_a?(String) && response["access_token"].present? &&
          response["refresh_token"].is_a?(String) && response["refresh_token"].present? &&
          (SCOPES - response["scope"].to_s.split).empty?
        raise MediaApi::Error, "Google n’a pas accordé les deux permissions et l’accès hors connexion. Relancez la connexion."
      end

      channel = Youtube::Client.channel_for(access_token: response.fetch("access_token"))
      invitation.with_current_authorization do
        YoutubeConnection.upsert({ id: 1, channel_id: channel.fetch(:id), channel_title: channel.fetch(:title),
          refresh_token: response.fetch("refresh_token") })
      end
    end
  end
end
