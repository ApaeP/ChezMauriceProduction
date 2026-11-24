require "test_helper"

class FrameIoWebhookTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @original = ENV.to_h.slice("FRAME_IO_PRIVATE_TRIAL", "FRAME_IO_WEBHOOK_SECRET")
    ENV.update("FRAME_IO_PRIVATE_TRIAL" => "1", "FRAME_IO_WEBHOOK_SECRET" => "test-webhook-signature")
    @event = {
      "type" => "file.ready", "resource" => { "type" => "file", "id" => "file-1" },
      "project" => { "id" => FrameIoPublication::PROJECT_ID }, "account" => { "id" => "account-1" }
    }
  end

  teardown do
    ENV.delete("FRAME_IO_PRIVATE_TRIAL")
    ENV.delete("FRAME_IO_WEBHOOK_SECRET")
    ENV.update(@original)
  end

  test "enqueues one durable job request for each documented trial signal with only signed context" do
    %w[file.upload.completed file.copied file.ready].each do |type|
      @event["type"] = type
      assert_enqueued_jobs 1 do
        assert_enqueued_with(job: FrameIoPublicationJob, args: [ "account-1", FrameIoPublication::PROJECT_ID, "file-1", type ]) do
          deliver(JSON.pretty_generate(@event) + "\n")
        end
      end
      assert_response :accepted
    end
  end

  test "metadata edits, premature file creation, folders and events from other projects are ignored" do
    assert_no_enqueued_jobs do
      deliver(@event.merge("type" => "metadata.value.updated").to_json)
      assert_response :no_content
      deliver(@event.merge("type" => "file.created").to_json)
      assert_response :no_content
      deliver(@event.merge("resource" => { "type" => "folder", "id" => "folder-1" }).to_json)
      assert_response :no_content
      # The related source of a copy cannot admit a file from a different signed project.
      deliver(@event.merge("type" => "file.copied", "project" => { "id" => "other" },
        "source_project" => { "id" => FrameIoPublication::PROJECT_ID }).to_json)
      assert_response :no_content
    end
  end

  test "altered bytes, bad credentials, missing headers and stale or future timestamps never enqueue" do
    body = @event.to_json
    now = Time.current.to_i
    assert_no_enqueued_jobs do
      deliver(body + " ", signed_body: body)
      assert_response :unauthorized
      deliver(body, secret: "not-the-webhook-secret")
      assert_response :unauthorized
      deliver(body, timestamp: now - 301)
      assert_response :unauthorized
      deliver(body, timestamp: now + 301)
      assert_response :unauthorized
      post frame_io_webhook_path, params: body, headers: { "Content-Type" => "application/json" }
      assert_response :unauthorized
      deliver("invalid-json", secret: "wrong")
      assert_response :unauthorized
    end
  end

  test "authenticated malformed events cannot become jobs" do
    assert_no_enqueued_jobs do
      [ "invalid-json", "null", "[]", "{}", @event.merge("resource" => "file").to_json,
        @event.merge("account" => { "id" => [] }).to_json,
        @event.merge("project" => nil).to_json,
        @event.merge("resource" => { "type" => "file", "id" => " " }).to_json ].each do |body|
        deliver(body)
        assert_response :bad_request
      end
    end
  end

  test "accepts a signed body at the size limit and rejects one extra byte" do
    body = @event.to_json.ljust(MediaApi::FrameIoWebhook::MAX_BODY_BYTES)
    assert_enqueued_jobs 1 do
      deliver(body)
      assert_response :accepted
      deliver(body + " ")
      assert_response :content_too_large
    end
  end

  test "stops reading oversized streams even without a declared length" do
    limit = MediaApi::FrameIoWebhook::MAX_BODY_BYTES
    input = StringIO.new("x" * (2 * limit))
    env = Rack::MockRequest.env_for(frame_io_webhook_path, method: "POST", input: input,
      "CONTENT_TYPE" => "application/json", "HTTP_X_FRAMEIO_REQUEST_TIMESTAMP" => Time.current.to_i.to_s,
      "HTTP_X_FRAMEIO_SIGNATURE" => "v0=#{"0" * 64}")
    env.delete("CONTENT_LENGTH")
    assert_no_enqueued_jobs do
      status, _, response_body = Rails.application.call(env)
      response_body.close if response_body.respond_to?(:close)
      assert_equal 413, status
      assert_equal limit + 1, input.pos
    end
  end

  test "trial activation and a configured signing secret are both required" do
    assert_no_enqueued_jobs do
      ENV.delete("FRAME_IO_PRIVATE_TRIAL")
      deliver(@event.to_json)
      assert_response :not_found

      ENV["FRAME_IO_PRIVATE_TRIAL"] = "1"
      ENV.delete("FRAME_IO_WEBHOOK_SECRET")
      deliver(@event.to_json, secret: "")
      assert_response :service_unavailable
    end
  end

  test "queue unavailability asks Frame.io to retry the delivery" do
    failing_job = Class.new(FrameIoPublicationJob) do
      def self.perform_later(*)
        raise SolidQueue::Job::EnqueueError, "queue unavailable"
      end
    end
    stub_const(Object, :FrameIoPublicationJob, failing_job) do
      deliver(@event.to_json)
      assert_response :service_unavailable
    end
  end

  private

  def deliver(body, timestamp: Time.current.to_i, secret: ENV.fetch("FRAME_IO_WEBHOOK_SECRET"), signed_body: body)
    signed = OpenSSL::HMAC.hexdigest("SHA256", secret, "v0:#{timestamp}:#{signed_body}")
    post frame_io_webhook_path, params: body, headers: {
      "Content-Type" => "application/json", "X-Frameio-Request-Timestamp" => timestamp.to_s,
      "X-Frameio-Signature" => "v0=#{signed}"
    }
  end
end
