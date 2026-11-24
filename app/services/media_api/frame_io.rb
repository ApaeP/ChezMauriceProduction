require "uri"

module MediaApi
  class FrameIo
    class OriginalUnavailable < Error; end

    READY_STATUSES = %w[ready transcoded].freeze
    PublicationExport = Data.define(:file_id, :project_id, :title, :description, :status, :byte_size, :content_type) do
      def ready?
        READY_STATUSES.include?(status)
      end

      def matches_original?(source)
        ready? && READY_STATUSES.include?(source["status"]) && source["type"] == "file" &&
          source["id"] == file_id && source["project_id"] == project_id &&
          source["file_size"] == byte_size && source["media_type"] == content_type
      end
    end

    API_HOST = "api.frame.io"
    TOKEN_URL = "https://ims-na1.adobelogin.com/ims/token/v3"
    DEFAULT_MEDIA_HOSTS = %w[assets.frame.io s3.amazonaws.com].freeze
    REDIRECT_STATUSES = [ 301, 302, 303, 307, 308 ].freeze
    MAX_REDIRECTS = 3

    attr_reader :account_id

    # Frame.io lists the accounts to which this Adobe identity actually has access.
    # Continue using the provider's opaque cursor. The bearer stays on the accounts endpoint.
    def self.accounts_for(access_token:)
      raise Error, "Jeton Adobe manquant" if access_token.blank?
      api = Connection.new(hosts: [ API_HOST ])
      accounts = {}
      Pagination.each_item(api, "/v4/accounts", headers: { "Authorization" => "Bearer #{access_token}" }) do |account|
        unless account["id"].is_a?(String) && account["id"].present? &&
            account["display_name"].is_a?(String) && account["display_name"].present?
          raise Error, "Compte Frame.io incomplet"
        end
        accounts[account["id"]] = { id: account["id"], name: account["display_name"] }
      end
      accounts.values
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
      @account_id = account_id
      @account_path = "/v4/accounts/#{path_segment(account_id)}"
      @base_url = "https://#{API_HOST}#{@account_path}/files"
      @api = api
      @media = media
    end

    def file(file_id)
      file_data(file_id)
    end

    # Only the inventory command traverses the project. It never asks for
    # expanded metadata, media links or the content of an individual file.
    def project_file_ids(project_id)
      project = data("https://#{API_HOST}#{@account_path}/projects/#{path_segment(project_id)}")
      unless project["id"] == project_id
        raise Error, "Identité du projet Frame.io inattendue"
      end
      pending = [ [ "folders", inventory_id(project["root_folder_id"]) ] ]
      visited = Set.new
      file_ids = Set.new
      while (container = pending.pop)
        next unless visited.add?(container)
        kind, container_id = container
        Pagination.each_item(@api, "#{@account_path}/#{kind}/#{container_id}/children") do |child|
          raise Error, "Élément rattaché à un autre projet Frame.io" unless child["project_id"] == project_id
          id = inventory_id(child["id"])
          case child["type"]
          when "file" then file_ids << id
          when "folder" then pending << [ "folders", id ]
          when "version_stack" then pending << [ "version_stacks", id ]
          else raise Error, "Type d’élément Frame.io inconnu dans le projet"
          end
        end
      end
      file_ids.to_a
    end

    def metadata(file_id)
      file_id = file(file_id).fetch("id") if file_id.to_s.start_with?("adobe:")
      response = data("#{@base_url}/#{path_segment(file_id)}/metadata")
      fields = response["metadata"]
      unless response["file_id"] == file_id && fields.is_a?(Array) && fields.all?(Hash)
        raise Error, "Métadonnées Frame.io invalides pour le fichier demandé"
      end
      fields
    end

    # Inspect only the asset referenced by the caller. "ready" describes
    # processing of the file by Frame.io, independently of any editorial choice.
    def publication_export(file_id, project_id:, title_field_id: nil, description_field_id: nil)
      raise ArgumentError, "Projet Frame.io de publication manquant" if project_id.blank?
      source = file(file_id)
      return unless source["project_id"] == project_id && source["type"] == "file"
      status = source["status"]
      raise Error, "Statut du fichier Frame.io manquant" unless status.is_a?(String) && status.present?
      content_type = source["media_type"]
      video = content_type.is_a?(String) && content_type.match?(%r{\Avideo/[a-zA-Z0-9][\w.+-]*\z})
      ready = READY_STATUSES.include?(status)
      return unless video || (content_type.nil? && !ready)

      fields = if title_field_id.present? || description_field_id.present?
        metadata(source.fetch("id")).index_by { |field| field["field_definition_id"] }
      else
        {}
      end
      title = text_value(fields[title_field_id]) if title_field_id.present?
      title ||= source["name"]
      description = text_value(fields[description_field_id]) if description_field_id.present?
      byte_size = source["file_size"]
      if ready && !(title.is_a?(String) && title.present? && byte_size.is_a?(Integer) && byte_size.positive?)
        raise Error, "Le titre ou la taille de l’export prêt sur Frame.io est invalide"
      end
      PublicationExport.new(file_id: source.fetch("id"), project_id: project_id, title: title, description: description,
        status: status, byte_size: byte_size, content_type: content_type)
    end

    # Append to a local binary File, Tempfile or StringIO. Restore its original
    # length if a network error or an incomplete transfer interrupts the copy.
    def download_original(file_id, output:, expected: nil)
      raise ArgumentError, "Placer le curseur en fin de fichier" unless output.pos == output.size

      offset = output.pos
      source = file_data(file_id, include_original: true)
      if expected && !expected.matches_original?(source)
        raise Error, "L’original Frame.io a changé depuis la vérification de l’export"
      end
      location = source.dig("media_links", "original", "download_url")
      raise OriginalUnavailable, "Frame.io ne fournit pas encore d’URL pour cet original" if location.blank?

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
      def file_data(file_id, include_original: false)
        url = "#{@base_url}/#{path_segment(file_id)}"
        url += "?include=media_links.original" if include_original
        source = data(url)
        id = source["id"]
        identifiers = [ id ]
        if source["adobe_id"].present?
          adobe_id = "adobe:#{source["adobe_id"]}"
          identifiers << adobe_id
          identifiers << "#{adobe_id}|#{source["adobe_version_id"]}" if source["adobe_version_id"].present?
        end
        raise Error, "Identité du fichier Frame.io inattendue" unless id.is_a?(String) && id.present? && identifiers.include?(file_id)
        source
      end

      def text_value(field)
        return if field.nil?
        unless field["field_type"] == "text" && (field["value"].nil? || field["value"].is_a?(String))
          raise Error, "Le champ éditorial Frame.io doit être de type text"
        end
        field["value"].presence
      end

      def inventory_id(id)
        # List endpoints return the Frame.io resource ID; Adobe aliases are
        # alternate path inputs rather than the canonical IDs in these results.
        raise Error, "Identifiant incomplet dans l’inventaire Frame.io" unless id.is_a?(String) && id.match?(/\A[a-zA-Z0-9_-]+\z/)
        id
      end

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
