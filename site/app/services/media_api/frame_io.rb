require "uri"

module MediaApi
  class FrameIo
    API_HOST = "api.frame.io"
    TOKEN_URL = "https://ims-na1.adobelogin.com/ims/token/v3"
    DEFAULT_MEDIA_HOSTS = %w[assets.frame.io s3.amazonaws.com].freeze
    REDIRECT_STATUSES = [ 301, 302, 303, 307, 308 ].freeze
    MAX_REDIRECTS = 3

    # Frame.io lists the accounts to which this Adobe identity actually has access.
    # Continue using the provider's opaque cursor. The bearer stays on the accounts endpoint.
    def self.accounts_for(access_token:)
      raise Error, "Jeton Adobe manquant" if access_token.blank?
      api = Connection.new(hosts: [ API_HOST ])
      path = "/v4/accounts"
      seen = Set.new
      accounts = {}
      while path
        link = URI.parse(path)
        unless link.relative? && link.host.nil? && link.path == "/v4/accounts" && link.fragment.nil? && seen.add?(path)
          raise Error, "Lien de pagination Frame.io invalide"
        end
        page = api.request(:get, "https://#{API_HOST}#{path}", headers: { "Authorization" => "Bearer #{access_token}" }).json
        unless page.is_a?(Hash) && page["data"].is_a?(Array) && page["links"].is_a?(Hash)
          raise Error, "Liste de comptes Frame.io illisible"
        end
        page["data"].each do |account|
          unless account.is_a?(Hash) && account["id"].is_a?(String) && account["id"].present? &&
              account["display_name"].is_a?(String) && account["display_name"].present?
            raise Error, "Compte Frame.io incomplet"
          end
          accounts[account["id"]] = { id: account["id"], name: account["display_name"] }
        end
        path = page["links"]["next"]
        raise Error, "Lien de pagination Frame.io invalide" unless path.nil? || path.is_a?(String)
      end
      accounts.values
    rescue URI::Error
      raise Error, "Lien de pagination Frame.io invalide", cause: nil
    end

    def self.from_env(env = ENV)
      case env["FRAME_IO_AUTH_MODE"]
      when "user"
        authorization = Adobe::Authorization.new(env: env)
        connection = FrameIoConnection.current
        raise Error, "Connecter d’abord le compte Adobe depuis la page de gestion." unless connection
        token = Adobe::UserToken.new(connection: connection, authorization: authorization)
        account_id = connection.account_id
      when "server_to_server"
        unless %w[ADOBE_CLIENT_ID ADOBE_CLIENT_SECRET ADOBE_SCOPES FRAME_IO_ACCOUNT_ID].all? { |key| env[key].present? }
          raise Error, "La connexion technique Adobe nécessite la configuration de l’exploitant."
        end
        token = Token.new(endpoint: TOKEN_URL, parameters: {
          grant_type: "client_credentials", client_id: env.fetch("ADOBE_CLIENT_ID"),
          client_secret: env.fetch("ADOBE_CLIENT_SECRET"), scope: env.fetch("ADOBE_SCOPES")
        })
        account_id = env.fetch("FRAME_IO_ACCOUNT_ID")
      else
        raise Error, "Configurer FRAME_IO_AUTH_MODE avec user ou server_to_server."
      end
      media_hosts = DEFAULT_MEDIA_HOSTS + env.fetch("FRAME_IO_MEDIA_HOSTS", "").split(",").map(&:strip)
      new(account_id: account_id, api: Connection.new(hosts: [ API_HOST ], token: token), media: Connection.new(hosts: media_hosts))
    end

    def initialize(account_id:, api:, media:)
      @base_url = "https://#{API_HOST}/v4/accounts/#{path_segment(account_id)}/files"
      @api = api
      @media = media
    end

    def file(file_id)
      data("#{@base_url}/#{path_segment(file_id)}")
    end

    def metadata(file_id)
      fields = data("#{@base_url}/#{path_segment(file_id)}/metadata")["metadata"]
      raise Error, "Frame.io a retourné des métadonnées illisibles" unless fields.is_a?(Array)
      fields
    end

    # Append to a local binary File, Tempfile or StringIO. Restore its original
    # length if a network error or an incomplete transfer interrupts the copy.
    def download_original(file_id, output:)
      raise ArgumentError, "Placer le curseur en fin de fichier" unless output.pos == output.size

      offset = output.pos
      source = data("#{@base_url}/#{path_segment(file_id)}?include=media_links.original")
      location = source.dig("media_links", "original", "download_url")
      raise Error, "Frame.io ne fournit pas d’URL pour cet original" if location.blank?

      stream(location, output)
      bytes = output.pos - offset
      if source["file_size"] && bytes != source["file_size"]
        raise Error, "Le nombre d’octets reçus diffère de la taille de l’original Frame.io"
      end
      bytes
    rescue StandardError
      if offset && output.pos != offset
        output.truncate(offset)
        output.seek(offset)
      end
      raise
    end

    private
      def path_segment(id)
        unless id.is_a?(String) && id.present? && !%w[. ..].include?(id)
          raise ArgumentError, "Identifiant Frame.io manquant ou invalide"
        end
        URI.encode_uri_component(id)
      end

      def data(url)
        response = @api.request(:get, url).json
        unless response.is_a?(Hash) && response["data"].is_a?(Hash)
          raise Error, "Réponse de l’API Frame.io illisible"
        end
        response.fetch("data")
      end

      def stream(location, output)
        (MAX_REDIRECTS + 1).times do
          response = @media.request(:get, location, expected: [ 200, *REDIRECT_STATUSES ], output: output)
          return if response.status == 200

          target = response["Location"]
          raise Error, "Redirection média Frame.io sans destination" if target.blank?
          location = URI.join(location, target).to_s
        end
        raise Error, "Trop de redirections pour l’original Frame.io"
      rescue URI::Error
        raise Error, "URL de redirection média Frame.io invalide", cause: nil
      end
  end
end
