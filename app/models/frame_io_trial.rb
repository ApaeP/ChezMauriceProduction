class FrameIoTrial < ApplicationRecord
  # The destination of a copy gets a new file ID. Its creation timestamp is
  # not documented as the copy time, so the cutover uses destination IDs.
  def self.open!
    frame_io = MediaApi::FrameIo.from_env
    identity = { account_id: frame_io.account_id, project_id: FrameIoPublication::PROJECT_ID }
    existing = find_by(identity)
    return existing if existing

    file_ids = frame_io.project_file_ids(identity.fetch(:project_id))
    create_or_find_by!(identity) { |trial| trial.existing_file_ids = file_ids }
  end
end
