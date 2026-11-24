require "tempfile"

module Youtube
  class PrivateTransfer
    def initialize(publication:, frame_io:, youtube:)
      @publication = publication
      @frame_io = frame_io
      @youtube = youtube
    end

    def call(source)
      # A temporary, seekable original bounds memory and disappears on process
      # exit. A retry can download it again and verify the exact bytes by hash.
      Tempfile.create(anonymous: true, binmode: true) do |io|
        @frame_io.download_original(source.file_id, output: io, expected: source)
        io.rewind
        digest = Digest::SHA256.new
        while (chunk = io.read(1.megabyte))
          digest.update(chunk)
        end
        sha256 = digest.hexdigest
        if @publication.source_sha256 && @publication.source_sha256 != sha256
          return @publication.review!("original_modifie")
        end
        if @publication.state == "pending"
          location = @youtube.start_session(expected_channel_id: FrameIoPublication::CHANNEL_ID,
            title: source.title, description: source.description.to_s, category_id: "1", privacy_status: "private",
            byte_size: io.size, content_type: source.content_type) do
            @publication.with_lock do
              return unless @publication.state == "pending"
              @publication.realisation.update!(title: source.title, description: source.description)
              @publication.update!(state: "creating_session", source_sha256: sha256)
            end
          end
          @publication.update!(state: "uploading", session_url: location)
        end
        id = @youtube.resume(expected_channel_id: FrameIoPublication::CHANNEL_ID,
          session_url: @publication.session_url, io: io, byte_size: io.size, content_type: source.content_type,
          expected_privacy: "private")
        @publication.transaction do
          @publication.realisation.update!(youtube_id: id)
          @publication.update!(state: "completed", session_url: nil)
        end
      end
    rescue Youtube::Client::SessionExpired
      @publication.review!("session_expiree")
    rescue Youtube::Client::ProtocolError
      @publication.review!("reponse_youtube_inattendue")
    rescue MediaApi::Error
      # No idempotency key on videos.insert. A crash can leave this marker too.
      raise unless @publication.reload.state == "creating_session"
      @publication.review!("creation_incertaine")
    end
  end
end
