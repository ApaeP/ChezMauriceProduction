module Adobe
  class UserToken
    def initialize(connection:, authorization:)
      @generation = connection.generation
      @authorization = authorization
    end

    def value
      current = current!
      if current.expires_at <= 60.seconds.from_now
        FrameIoConnection.synchronize do
          current = current!
          if current.expires_at <= 60.seconds.from_now
            begin
              grant = @authorization.refresh(current.refresh_token)
            rescue MediaApi::Token::InvalidGrant
              update_current!(refresh_token: nil, access_token: nil, expires_at: nil)
              raise
            end
            update_current!(grant.merge("expires_at" => Time.iso8601(grant.fetch("expires_at"))))
            current = current!
          end
        end
      end
      current.access_token
    end

    def invalidate(rejected_token)
      FrameIoConnection.synchronize do
        current = current!
        update_current!(expires_at: Time.current) if current.access_token == rejected_token
      end
    end

    def inspect
      "#<#{self.class.name} [FILTERED]>"
    end

    private
      def current!
        current = FrameIoConnection.uncached { FrameIoConnection.find_by(generation: @generation) }
        raise MediaApi::Error, "La connexion Frame.io a changé. Recharger le client." unless current
        raise MediaApi::Token::InvalidGrant, "Le compte Adobe doit être reconnecté." if current.reconnect_required?
        current
      end

      def update_current!(attributes)
        unless FrameIoConnection.where(id: 1, generation: @generation).update_all(attributes.merge(updated_at: Time.current)) == 1
          raise MediaApi::Error, "La connexion Frame.io a changé. Recharger le client."
        end
      end
  end
end
