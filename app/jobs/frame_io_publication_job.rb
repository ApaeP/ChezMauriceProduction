class FrameIoPublicationJob < ApplicationJob
  EVENTS = %w[file.upload.completed file.ready file.copied].freeze

  def perform(account_id, project_id, file_id, event_type)
    return unless FrameIoPublication.enabled? && project_id == FrameIoPublication::PROJECT_ID && EVENTS.include?(event_type)

    identity = { account_id: account_id, project_id: project_id, file_id: file_id }
    publication = FrameIoPublication.find_by(identity)
    return if publication && !publication.processing?

    frame_io = MediaApi::FrameIo.from_env
    return unless frame_io.account_id == account_id
    trial = FrameIoTrial.find_by!(account_id: account_id, project_id: project_id)
    return if trial.existing_file_ids.include?(file_id)
    source = frame_io.publication_export(file_id, project_id: project_id,
      title_field_id: ENV["FRAME_IO_TITLE_FIELD_ID"].presence, description_field_id: ENV["FRAME_IO_DESCRIPTION_FIELD_ID"].presence)
    return unless source
    return if trial.existing_file_ids.include?(source.file_id)

    if source.content_type.nil?
      raise MediaApi::FrameIo::OriginalUnavailable, "Type du fichier en préparation."
    end
    identity[:file_id] = source.file_id
    publication ||= FrameIoPublication.prepare!(identity, source)
    return unless publication.processing?
    raise MediaApi::FrameIo::OriginalUnavailable, "Original en préparation." unless source.ready?

    Youtube::PrivateTransfer.new(publication: publication, frame_io: frame_io, youtube: Youtube::Client.from_env).call(source)
  rescue MediaApi::FrameIo::OriginalUnavailable, MediaApi::TransportError, Youtube::Client::RetryLater => error
    retry_transfer(error)
  rescue MediaApi::HttpError => error
    raise unless [ 404, 408, 429, 500, 502, 503, 504 ].include?(error.status)
    retry_transfer(error)
  end

  private
    # Once attempts are exhausted Solid Queue retains the failed execution.
    # It can be retried after inspection with the same file and upload session.
    def retry_transfer(error)
      raise error if executions >= 12
      delay = [ 15 * (2 ** (executions - 1)), 15.minutes.to_i ].min
      if error.respond_to?(:retry_after) && (header = error.retry_after).present?
        suggested = retry_after_seconds(header)
        delay = [ delay, suggested ].compact.max
      end
      raise error unless retry_job(wait: delay.seconds)
    end

    def retry_after_seconds(header)
      return header.to_i if header.match?(/\A\d+\z/)
      (Time.httpdate(header) - Time.current).ceil
    rescue ArgumentError
      nil
    end
end
