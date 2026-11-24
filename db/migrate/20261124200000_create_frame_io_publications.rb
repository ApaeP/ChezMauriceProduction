class CreateFrameIoPublications < ActiveRecord::Migration[8.1]
  def change
    create_table :frame_io_publications do |t|
      t.string :account_id, null: false
      t.string :project_id, null: false
      t.string :file_id, null: false
      t.references :realisation, null: false, foreign_key: true, index: { unique: true }
      t.string :state, null: false, default: "pending"
      t.string :source_sha256
      t.text :session_url
      t.string :review_reason
      t.timestamps
      t.index %i[account_id project_id file_id], unique: true
      t.check_constraint "state IN ('pending', 'creating_session', 'uploading', 'completed', 'review')", name: "frame_io_publication_state"
    end
  end
end
