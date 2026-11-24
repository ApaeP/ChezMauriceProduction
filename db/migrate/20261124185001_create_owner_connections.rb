class CreateOwnerConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_connections do |t|
      t.string :channel_id, null: false
      t.string :channel_title, null: false
      t.text :refresh_token, null: false
      t.timestamps
      t.check_constraint "id = 1", name: "single_active_youtube_connection"
    end

    create_table :owner_invitations do |t|
      t.string :provider, null: false
      t.check_constraint "provider IN ('adobe', 'youtube')", name: "owner_invitation_provider"
      t.string :code_digest, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :redeemed_at
      t.string :state_digest
      t.boolean :state_used, default: false, null: false
      t.text :pending_adobe_grant
      t.text :pkce_verifier
    end
  end
end
