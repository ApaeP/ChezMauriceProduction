require "base64"

module Adobe
  class Authorization
    AUTHORIZE_URL = "https://ims-na1.adobelogin.com/ims/authorize/v2"

    def initialize(redirect_uri: nil, env: ENV)
      @client_id = env["ADOBE_WEB_CLIENT_ID"].presence
      @client_secret = env["ADOBE_WEB_CLIENT_SECRET"].presence
      @scopes = env["ADOBE_WEB_SCOPES"].to_s.split(/[\s,]+/).reject(&:empty?)
      @redirect_uri = redirect_uri
      unless env["FRAME_IO_AUTH_MODE"] == "user" && @client_id && @client_secret && @scopes.any? &&
          ActiveRecord::Encryption.config.has_primary_key? && ActiveRecord::Encryption.config.has_key_derivation_salt?
        raise MediaApi::Error, "La connexion Adobe utilisateur nécessite la configuration de l’exploitant."
      end
      @http = MediaApi::Connection.new(hosts: [ "ims-na1.adobelogin.com" ])
    end

    def inspect
      "#<#{self.class.name} [FILTERED]>"
    end

    def url(state:)
      raise MediaApi::Error, "Le retour Adobe Web App nécessite une adresse HTTPS." unless @redirect_uri.to_s.start_with?("https://")

      parameters = { client_id: @client_id, redirect_uri: @redirect_uri,
        scope: (@scopes | %w[openid offline_access]).join(","), state: state, response_type: "code", response_mode: "fragment" }
      "#{AUTHORIZE_URL}?#{URI.encode_www_form(parameters)}"
    end

    def connect!(code:, invitation:)
      grant = exchange(grant_type: "authorization_code", code: code)
      accounts = MediaApi::FrameIo.accounts_for(access_token: grant.fetch("access_token")).map(&:stringify_keys)
      raise MediaApi::Error, "Aucun compte Frame.io V4 accessible avec cette autorisation." if accounts.empty?

      write_consent(invitation) do |current|
        if accounts.one?
          activate!(accounts.first, grant, current)
          :active
        else
          current.update!(pending_adobe_grant: grant.merge("accounts" => accounts, "selection_id" => SecureRandom.urlsafe_base64(24)))
          :choose_account
        end
      end
    end

    def select_account!(account_id:, selection_id:, invitation:)
      write_consent(invitation) do |current|
        grant = current.pending_adobe_grant
        unless grant && selection_id.is_a?(String) && grant.fetch("selection_id") == selection_id
          raise MediaApi::Error, "Cette sélection de compte Adobe a expiré."
        end
        account = grant.fetch("accounts").find { |entry| entry.fetch("id") == account_id }
        raise MediaApi::Error, "Sélectionner un compte proposé par Frame.io." unless account
        activate!(account, grant, current)
      end
    end

    def refresh(refresh_token)
      exchange(grant_type: "refresh_token", refresh_token: refresh_token)
    end

    private
      def write_consent(invitation, &block)
        raise MediaApi::Error, "Cette invitation ne donne pas accès à Adobe." unless invitation.provider == "adobe"
        FrameIoConnection.synchronize do
          invitation.with_current_authorization(&block)
        end
      end

      def activate!(account, grant, invitation)
        FrameIoConnection.upsert({ id: 1, account_id: account.fetch("id"), account_name: account.fetch("name"),
          generation: SecureRandom.uuid, access_token: grant.fetch("access_token"), refresh_token: grant.fetch("refresh_token"),
          expires_at: Time.iso8601(grant.fetch("expires_at")) })
        invitation.update!(pending_adobe_grant: nil)
      end

      def exchange(parameters)
        basic = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        response = @http.request(:post, MediaApi::FrameIo::TOKEN_URL, headers: {
          "Authorization" => "Basic #{basic}", "Content-Type" => "application/x-www-form-urlencoded"
        }, body: URI.encode_www_form(parameters), expected: [ 200, 400 ])
        fields = response.json
        if response.status == 400
          if fields.is_a?(Hash) && fields["error"] == "invalid_grant"
            raise MediaApi::Token::InvalidGrant, "L’autorisation Adobe a expiré ou a été révoquée. Reconnecter le compte."
          end
          raise MediaApi::HttpError.new(response.status, response["Retry-After"])
        end
        unless fields.is_a?(Hash) && fields["token_type"].to_s.casecmp?("bearer") &&
            fields["access_token"].is_a?(String) && fields["access_token"].present? &&
            fields["refresh_token"].is_a?(String) && fields["refresh_token"].present? && fields["expires_in"].to_i.positive?
          raise MediaApi::Error, "Adobe n’a pas fourni une paire de jetons utilisable hors connexion."
        end
        { "access_token" => fields.fetch("access_token"), "refresh_token" => fields.fetch("refresh_token"),
          "expires_at" => fields.fetch("expires_in").to_i.seconds.from_now.iso8601(6) }
      end
  end
end
