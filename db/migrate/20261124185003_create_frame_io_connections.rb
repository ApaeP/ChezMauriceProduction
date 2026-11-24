class CreateFrameIoConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :frame_io_connections do |t|
      t.string :account_id, null: false
      t.string :account_name, null: false
      t.string :generation, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.timestamps
      t.check_constraint "id = 1", name: "single_active_frame_io_connection"
    end
  end
end
