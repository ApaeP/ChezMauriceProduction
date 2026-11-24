require "openssl"

module MediaApi
  # A Rack endpoint keeps the signed request body out of Rails parameter parsing.
  class FrameIoWebhook
    MAX_BODY_BYTES = 64.kilobytes

    def self.call(env)
      new(ActionDispatch::Request.new(env)).call
    end

    def initialize(request)
      @request = request
    end

    def call
      return response(404) unless FrameIoPublication.enabled?
      secret = ENV["FRAME_IO_WEBHOOK_SECRET"]
      return response(503) if secret.blank?

      timestamp = @request.get_header("HTTP_X_FRAMEIO_REQUEST_TIMESTAMP").to_s
      signature = @request.get_header("HTTP_X_FRAMEIO_SIGNATURE").to_s
      return response(401) unless valid_headers?(timestamp, signature)
      return response(413) if @request.get_header("CONTENT_LENGTH").to_i > MAX_BODY_BYTES

      body = @request.get_header("rack.input")&.read(MAX_BODY_BYTES + 1).to_s
      return response(413) if body.bytesize > MAX_BODY_BYTES
      digest = OpenSSL::HMAC.new(secret, "SHA256").update("v0:#{timestamp}:").update(body).hexdigest
      return response(401) unless ActiveSupport::SecurityUtils.secure_compare("v0=#{digest}", signature)

      event = JSON.parse(body)
      return response(400) unless event.is_a?(Hash) && identifier?(event["type"])
      return response(204) unless FrameIoPublicationJob::EVENTS.include?(event["type"])

      resource = event["resource"]
      return response(400) unless resource.is_a?(Hash) && identifier?(resource["type"])
      return response(204) unless resource["type"] == "file"

      account_id = object_id_from(event["account"])
      project_id = object_id_from(event["project"])
      file_id = object_id_from(resource)
      return response(400) unless account_id && project_id && file_id
      return response(204) unless project_id == FrameIoPublication::PROJECT_ID

      # The signed project is a first filter. The job rereads the actual file
      # before admitting a deposit or copy.
      job = FrameIoPublicationJob.perform_later(account_id, project_id, file_id, event["type"])
      response(job ? 202 : 503)
    rescue JSON::ParserError
      response(400)
    rescue SolidQueue::Job::EnqueueError, ActiveJob::EnqueueError => error
      Rails.logger.error("Mise en file du webhook Frame.io impossible (#{error.class})")
      response(503)
    end

    private
      def valid_headers?(timestamp, signature)
        timestamp.match?(/\A[0-9]{1,12}\z/) && signature.match?(/\Av0=[0-9a-f]{64}\z/) &&
          (Time.now.to_i - timestamp.to_i).abs <= 5.minutes.to_i
      end

      def object_id_from(object)
        object["id"] if object.is_a?(Hash) && identifier?(object["id"])
      end

      def identifier?(value)
        value.is_a?(String) && value.present?
      end

      def response(status)
        [ status, { "cache-control" => "no-store" }, [] ]
      end
  end
end
