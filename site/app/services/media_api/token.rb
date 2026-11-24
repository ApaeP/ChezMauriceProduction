module MediaApi
  class Token
    class InvalidGrant < Error; end

    def initialize(endpoint:, parameters:)
      @endpoint = endpoint
      @parameters = parameters
      @http = Connection.new(hosts: [ URI.parse(endpoint).host ])
    end

    def value
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return @value if @value && now < @expires_at

      response = @http.request(:post, @endpoint,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: URI.encode_www_form(@parameters), expected: [ 200, 400 ])
      if response.status == 400
        begin
          error = JSON.parse(response.body)
        rescue JSON::ParserError
          raise HttpError.new(response.status, response["Retry-After"]), cause: nil
        end
        if error.is_a?(Hash) && error["error"] == "invalid_grant"
          raise InvalidGrant, "L’autorisation OAuth est expirée ou révoquée. Renouveler le consentement."
        end
        raise HttpError.new(response.status, response["Retry-After"])
      end
      fields = response.json
      unless fields.is_a?(Hash) && fields["access_token"].is_a?(String) &&
          fields["access_token"].present? && fields["token_type"].to_s.casecmp?("bearer") &&
          fields["expires_in"].to_i.positive?
        raise Error, "Jeton OAuth absent ou invalide"
      end
      @expires_at = now + fields["expires_in"].to_i - 60
      @value = fields.fetch("access_token")
    end

    def invalidate(rejected_token)
      @value = nil if @value == rejected_token
    end

    def inspect
      "#<#{self.class.name} [FILTERED]>"
    end
  end
end
