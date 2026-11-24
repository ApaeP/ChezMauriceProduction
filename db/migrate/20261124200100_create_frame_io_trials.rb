class CreateFrameIoTrials < ActiveRecord::Migration[8.1]
  def change
    create_table :frame_io_trials do |t|
      t.string :account_id, null: false
      t.string :project_id, null: false
      t.json :existing_file_ids, null: false
      t.timestamps
      t.index %i[account_id project_id], unique: true
    end
  end
end
