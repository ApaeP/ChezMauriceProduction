require "net/http"
require "json"

module MediaApi
  class Connection
    Response = Data.define(:status, :headers, :body) do
      def inspect
        "#<#{self.class.name} status=#{status}>"
      end
      alias_method :to_s, :inspect

      def [](header)
        headers[header.downcase]
      end

      def json
        JSON.parse(body)
      rescue JSON::ParserError
        raise Error, "Réponse JSON illisible", cause: nil
      end
    end

    METHODS = { get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put }.freeze
    MAX_RESPONSE_BYTES = 2.megabytes

    def initialize(hosts:, token: nil)
      @hosts = hosts
      @token = token
    end

    def request(method, url, headers: {}, body: nil, expected: [ 200 ], output: nil)
      uri = validated_uri(url)
      refreshed = false
      begin
        request = METHODS.fetch(method).new(uri, headers)
        if @token
          bearer = @token.value
          request["Authorization"] = "Bearer #{bearer}"
        end
        request.body = body
        execute(uri, request, expected, output)
      rescue HttpError => error
        if error.status == 401 && bearer
          @token.invalidate(bearer)
          if method == :get && !refreshed
            refreshed = true
            retry
          end
        end
        raise
      end
    end

    private
      def validated_uri(url)
        uri = URI.parse(url.to_s)
        unless uri.is_a?(URI::HTTPS) && uri.port == 443 && uri.userinfo.nil? && uri.fragment.nil? && @hosts.include?(uri.host)
          raise Error, "Destination HTTPS non autorisée"
        end
        uri
      rescue URI::InvalidURIError
        raise Error, "Adresse HTTPS invalide", cause: nil
      end

      def execute(uri, request, expected, output)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 60
        http.write_timeout = 60
        http.ignore_eof = false
        http.max_retries = 0
        http.start do |client|
          client.request(request) do |response|
            status = response.code.to_i
            raise HttpError.new(status, response["Retry-After"]) unless expected.include?(status)

            body = +"".b
            response.read_body do |chunk|
              if output && status == 200
                output.write(chunk)
              else
                raise Error, "Réponse API trop volumineuse" if body.bytesize + chunk.bytesize > MAX_RESPONSE_BYTES
                body << chunk
              end
            end
            return Response.new(status, response.each_header.to_h, body)
          end
        end
      rescue Timeout::Error, IOError, SystemCallError, SocketError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::ProtocolError
        # Les exceptions réseau peuvent contenir une URL de session ou de média signée.
        raise TransportError, "Échange HTTPS interrompu", cause: nil
      end
  end
end
