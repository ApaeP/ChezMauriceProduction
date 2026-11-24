# Run from the application root with: bundle exec ruby test/smoke/frame_io_publication.rb
require "tmpdir"
require "timeout"
require "webmock"

module FrameIoWorkerSmoke
  extend self
  extend WebMock::API

  VIDEOS = { "depot" => "depot000001", "copie" => "copie000001" }.freeze
  ACCOUNT = "compte-de-recette"
  SECRET = "signature-de-recette"

  def boot(directory)
    ENV.update(
      "RAILS_ENV" => "test", "DATABASE_URL" => "sqlite3:#{directory}/primary.sqlite3",
      "FRAME_IO_PRIVATE_TRIAL" => "1", "FRAME_IO_WEBHOOK_SECRET" => SECRET,
      "FRAME_IO_AUTH_MODE" => "server_to_server", "FRAME_IO_ACCOUNT_ID" => ACCOUNT,
      "ADOBE_CLIENT_ID" => "recette", "ADOBE_CLIENT_SECRET" => "recette", "ADOBE_SCOPES" => "recette",
      "YOUTUBE_CLIENT_ID" => "recette", "YOUTUBE_CLIENT_SECRET" => "recette",
      "FRAME_IO_TITLE_FIELD_ID" => nil, "FRAME_IO_DESCRIPTION_FIELD_ID" => nil,
      "SOLID_QUEUE_SUPERVISOR_MODE" => "async"
    )
    WebMock.enable!
    WebMock.disable_net_connect!
    require_relative "../../config/environment"
    ActiveJob::Base.queue_adapter = :solid_queue
    SolidQueue::Record.establish_connection(adapter: "sqlite3", database: "#{directory}/queue.sqlite3", timeout: 5000)
  end

  def prepare(directory)
    ActiveRecord::Migration.verbose = false
    primary = ActiveRecord::Base.connection_db_config
    raise "La base principale doit être temporaire" unless primary.database == "#{directory}/primary.sqlite3"
    ActiveRecord::Base.establish_connection(SolidQueue::Record.connection_db_config)
    load Rails.root.join("db/queue_schema.rb")
    ActiveRecord::Base.establish_connection(primary)
    load Rails.root.join("db/schema.rb")
    YoutubeConnection.create!(id: 1, channel_id: FrameIoPublication::CHANNEL_ID, channel_title: "Recette", refresh_token: "recette")
    FrameIoTrial.create!(project_id: FrameIoPublication::PROJECT_ID, account_id: ACCOUNT, existing_file_ids: [ "ancien" ])
  end

  def mock_providers(directory)
    token = { access_token: "simulation", token_type: "Bearer", expires_in: 3600 }.to_json
    stub_request(:post, MediaApi::FrameIo::TOKEN_URL).to_return(body: token)
    stub_request(:post, Youtube::Client::TOKEN_URL).to_return(body: token)
    channel = { id: FrameIoPublication::CHANNEL_ID, snippet: { title: "Recette" } }
    stub_request(:get, Youtube::Client::CHANNEL_URL).to_return(body: { items: [ channel ] }.to_json)

    VIDEOS.each do |file_id, youtube_id|
      bytes = "octets de recette pour #{file_id}"
      api = "https://api.frame.io/v4/accounts/#{ACCOUNT}/files/#{file_id}"
      original = "https://assets.frame.io/#{file_id}"
      file = { id: file_id, project_id: FrameIoPublication::PROJECT_ID, type: "file", status: "ready",
        name: file_id, file_size: bytes.bytesize, media_type: "video/mp4", created_at: "2019-01-01T00:00:00Z" }
      stub_request(:get, api).to_return(body: { data: file }.to_json)
      stub_request(:get, "#{api}?include=media_links.original").to_return(
        body: { data: file.merge(media_links: { original: { download_url: original } }) }.to_json)
      stub_request(:get, original).to_return(body: bytes)

      session = "https://www.googleapis.com#{Youtube::Client::UPLOAD_PATH}?upload_id=#{file_id}"
      stub_request(:post, Youtube::Client::CREATE_URL).with { |request|
        data = JSON.parse(request.body)
        data.dig("snippet", "title") == file_id && data.dig("status", "privacyStatus") == "private"
      }.to_return do
        File.open("#{directory}/creations", "a") { |io| io.puts(file_id) }
        { status: 200, headers: { "Location" => session } }
      end
      stub_request(:put, session).with(headers: { "Content-Range" => "bytes */#{bytes.bytesize}" }).to_return(status: 308)
      stub_request(:put, session).with(body: bytes, headers: {
        "Content-Range" => "bytes 0-#{bytes.bytesize - 1}/#{bytes.bytesize}"
      }).to_return(body: { id: youtube_id, snippet: { channelId: channel.fetch(:id) }, status: { privacyStatus: "private" } }.to_json)
    end
  end

  def deliver(type, file_id, expected_status)
    event = { type: type, account: { id: ACCOUNT }, project: { id: FrameIoPublication::PROJECT_ID },
      resource: { type: "file", id: file_id } }.to_json
    timestamp = Time.now.to_i
    signature = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "v0:#{timestamp}:#{event}")
    response = Rack::MockRequest.new(Rails.application).post("/webhooks/frame-io", input: event, "CONTENT_TYPE" => "application/json",
      "HTTP_X_FRAMEIO_REQUEST_TIMESTAMP" => timestamp.to_s, "HTTP_X_FRAMEIO_SIGNATURE" => "v0=#{signature}")
    raise "#{type} : réponse HTTP #{response.status}" unless response.status == expected_status
  end

  def check(directory)
    %w[file.upload.completed file.ready file.upload.completed].each { |type| deliver(type, "depot", 202) }
    %w[file.copied file.ready file.copied].each { |type| deliver(type, "copie", 202) }
    deliver("metadata.value.updated", "ancien", 204)
    raise "Les six jobs doivent être en SQLite avant démarrage" unless SolidQueue::Job.count == 6
    pid = Process.spawn(RbConfig.ruby, __FILE__, "--worker", directory)
    Timeout.timeout(35) do
      until SolidQueue::Job.count.zero?
        failure = SolidQueue::FailedExecution.first
        raise "Échec du worker : #{failure.error['exception_class']}" if failure
        sleep 0.1
      end
    end
    expected = VIDEOS.keys.sort
    raise "Nombre de créations privées incorrect" unless File.readlines("#{directory}/creations", chomp: true).sort == expected
    raise "Transferts incomplets" unless FrameIoPublication.where(state: "completed").pluck(:file_id).sort == expected
    raise "Brouillons incorrects" unless Realisation.where(published: false).pluck(:title, :youtube_id).to_h == VIDEOS && Realisation.count == 2
    puts "OK — 6 jobs SQLite traités par bin/jobs, 2 créations YouTube privées simulées, 2 brouillons."
  ensure
    if pid
      Process.kill("TERM", pid)
      begin
        Timeout.timeout(10) { Process.wait(pid) }
      rescue Timeout::Error
        Process.kill("KILL", pid)
        Process.wait(pid)
      end
    end
  end
end

if ARGV.first == "--worker"
  directory = ARGV.fetch(1)
  FrameIoWorkerSmoke.boot(directory)
  FrameIoWorkerSmoke.mock_providers(directory)
  ARGV.replace(%w[start --skip-recurring])
  load Rails.root.join("bin/jobs")
else
  Dir.mktmpdir("chez-maurice-worker-") do |directory|
    FrameIoWorkerSmoke.boot(directory)
    FrameIoWorkerSmoke.prepare(directory)
    FrameIoWorkerSmoke.check(directory)
  end
end
