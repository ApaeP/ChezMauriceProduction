require "uri"

module Youtube
  class Client
    GOOGLE_HOST = "www.googleapis.com"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    CHANNEL_URL = "https://#{GOOGLE_HOST}/youtube/v3/channels?mine=true&part=snippet"
    UPLOAD_PATH = "/upload/youtube/v3/videos"
    CREATE_URL = "https://#{GOOGLE_HOST}#{UPLOAD_PATH}?uploadType=resumable&part=snippet,status"
    CHUNK_SIZE = 8 * 1024 * 1024
    TEMPORARY_STATUSES = [ 429, 500, 502, 503, 504 ].freeze
    UPLOAD_STATUSES = [ 200, 201, 308, 404, 410, *TEMPORARY_STATUSES ].freeze

    class ProtocolError < MediaApi::Error; end
    class SessionExpired < MediaApi::Error; end
    class ChannelUnavailable < MediaApi::Error; end

    class RetryLater < MediaApi::Error
      attr_reader :retry_after

      def initialize(message, retry_after: nil)
        @retry_after = retry_after
        super(message)
      end
    end

    def self.from_env(env = ENV)
      new(client_id: env.fetch("YOUTUBE_CLIENT_ID"), client_secret: env.fetch("YOUTUBE_CLIENT_SECRET"))
    end

    def self.channel_for(access_token:)
      raise ChannelUnavailable, "Le consentement Google ne contient aucun jeton." if access_token.blank?
      api = MediaApi::Connection.new(hosts: [ GOOGLE_HOST ])
      resource = api.request(:get, CHANNEL_URL, headers: { "Authorization" => "Bearer #{access_token}" }).json
      items = resource["items"] if resource.is_a?(Hash)
      if items.is_a?(Array) && items.one? && items.first.is_a?(Hash) && resource["nextPageToken"].blank?
        id = items.first["id"]
        title = items.first["snippet"]["title"] if items.first["snippet"].is_a?(Hash)
        return { id: id, title: title } if id.is_a?(String) && id.present? && title.is_a?(String) && title.present?
      end
      raise ChannelUnavailable, "Google doit identifier une seule chaîne pour ce compte."
    end

    def initialize(client_id:, client_secret:)
      @client_id = client_id
      @client_secret = client_secret
    end

    def inspect
      "#<#{self.class.name}>"
    end

    def start_session(expected_channel_id:, title:, description:, category_id:, privacy_status:, byte_size:, content_type:)
      validate_media!(byte_size, content_type)
      raise ArgumentError, "Le titre et la catégorie YouTube sont requis." if title.blank? || category_id.blank?
      unless %w[public unlisted private].include?(privacy_status)
        raise ArgumentError, "Visibilité YouTube attendue : public, unlisted ou private."
      end

      metadata = {
        snippet: { title: title, description: description, categoryId: category_id.to_s },
        status: { privacyStatus: privacy_status }
      }
      api = connection_for(expected_channel_id)
      # The workflow records its intent only after authentication and channel checks.
      yield if block_given?
      response = api.request(:post, CREATE_URL, headers: {
        "Content-Type" => "application/json; charset=utf-8",
        "X-Upload-Content-Type" => content_type,
        "X-Upload-Content-Length" => byte_size.to_s
      }, body: JSON.generate(metadata), expected: [ 200, 201 ])
      validate_session!(response["Location"])
    end

    # The caller must persist the session URL and keep the original file immutable.
    def resume(expected_channel_id:, session_url:, io:, byte_size:, content_type:, expected_privacy: nil)
      validate_session!(session_url)
      validate_media!(byte_size, content_type)
      raise ArgumentError, "La taille du fichier source a changé." unless io.size == byte_size

      api = connection_for(expected_channel_id)
      response = put(api, session_url, { "Content-Length" => "0", "Content-Range" => "bytes */#{byte_size}" })
      return video_id(response, expected_channel_id, expected_privacy) unless response.status == 308

      offset = next_offset(response, byte_size)
      loop do
        if offset == byte_size
          raise RetryLater, "Tous les octets sont reçus. Sonder à nouveau pour obtenir l’identifiant."
        end
        io.seek(offset)
        length = [ CHUNK_SIZE, byte_size - offset ].min
        chunk = io.read(length)
        raise IOError, "Lecture incomplète du fichier source." unless chunk&.bytesize == length

        response = put(api, session_url, {
          "Content-Type" => content_type, "Content-Length" => length.to_s,
          "Content-Range" => "bytes #{offset}-#{offset + length - 1}/#{byte_size}"
        }, chunk)
        if response.status != 308
          raise ProtocolError, "YouTube a terminé avant le dernier fragment." unless offset + length == byte_size
          return video_id(response, expected_channel_id, expected_privacy)
        end

        confirmed = next_offset(response, byte_size)
        if confirmed == offset
          raise RetryLater, "YouTube n’a pas encore confirmé le fragment. Sonder à nouveau la session."
        end
        unless confirmed.between?(offset + 1, offset + length)
          raise ProtocolError, "La plage confirmée par YouTube dépasse le fragment envoyé."
        end
        offset = confirmed
      end
    end

    private
      def connection_for(expected_channel_id)
        account = YoutubeConnection.current
        if expected_channel_id.blank? || !account || expected_channel_id != account.channel_id
          raise ChannelUnavailable, "La chaîne liée à cet export n’est plus connectée."
        end
        token = MediaApi::Token.new(endpoint: TOKEN_URL, parameters: {
          grant_type: "refresh_token", client_id: @client_id, client_secret: @client_secret, refresh_token: account.refresh_token
        })
        unless self.class.channel_for(access_token: token.value).fetch(:id) == expected_channel_id
          raise ChannelUnavailable, "Le compte Google autorisé ne correspond plus à la chaîne de cet export."
        end
        MediaApi::Connection.new(hosts: [ GOOGLE_HOST ], token: token)
      end

      def validate_media!(byte_size, content_type)
        raise ArgumentError, "Taille vidéo positive requise." unless byte_size.is_a?(Integer) && byte_size.positive?
        unless content_type == "application/octet-stream" || /\Avideo\/[a-z0-9][a-z0-9.+_-]*\z/i.match?(content_type)
          raise ArgumentError, "Type de contenu vidéo invalide."
        end
      end

      def validate_session!(url)
        uri = URI.parse(url.to_s)
        if uri.is_a?(URI::HTTPS) && uri.host == GOOGLE_HOST && uri.port == 443 &&
            uri.userinfo.nil? && uri.fragment.nil? && uri.path == UPLOAD_PATH
          ids = URI.decode_www_form(uri.query.to_s).select { |key, _| key == "upload_id" }
          return url if ids.size == 1 && ids.first.last.present?
        end
        raise ProtocolError, "URL de session YouTube invalide."
      rescue URI::InvalidURIError, ArgumentError
        raise ProtocolError, "URL de session YouTube invalide.", cause: nil
      end

      def put(api, url, headers, body = nil)
        response = api.request(:put, url, headers: headers, body: body, expected: UPLOAD_STATUSES)
        if [ 404, 410 ].include?(response.status)
          raise SessionExpired, "La session YouTube a expiré."
        end
        if TEMPORARY_STATUSES.include?(response.status) || (response.status == 308 && response["Retry-After"].present?)
          raise RetryLater.new("YouTube demande de reprendre la session (HTTP #{response.status}).",
            retry_after: response["Retry-After"])
        end
        response
      end

      def next_offset(response, byte_size)
        range = response["Range"]
        return 0 unless range
        match = /\Abytes=0-(\d+)\z/i.match(range)
        raise ProtocolError, "Plage de reprise YouTube invalide." unless match

        offset = match[1].to_i + 1
        raise ProtocolError, "Plage de reprise hors du fichier." if offset > byte_size
        offset
      end

      def video_id(response, expected_channel_id, expected_privacy)
        begin
          resource = response.json
        rescue MediaApi::Error
          raise ProtocolError, "Réponse vidéo finale illisible.", cause: nil
        end
        unless resource.is_a?(Hash) && resource["id"].is_a?(String) && /\A[a-zA-Z0-9_-]{11}\z/.match?(resource["id"])
          raise ProtocolError, "YouTube a terminé sans identifiant vidéo valide."
        end
        if expected_privacy && !(resource["status"].is_a?(Hash) && resource["status"]["privacyStatus"] == expected_privacy &&
            resource["snippet"].is_a?(Hash) && resource["snippet"]["channelId"] == expected_channel_id)
          raise ProtocolError, "La réponse finale ne confirme pas la visibilité et la chaîne attendues."
        end
        resource.fetch("id")
      end
  end
end
