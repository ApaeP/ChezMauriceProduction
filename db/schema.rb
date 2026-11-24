# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_24_200100) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "categories_realisations", id: false, force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "realisation_id", null: false
    t.index ["category_id", "realisation_id"], name: "idx_on_category_id_realisation_id_7f686e2fcb", unique: true
    t.index ["realisation_id"], name: "index_categories_realisations_on_realisation_id"
  end

  create_table "frame_io_connections", force: :cascade do |t|
    t.string "account_id", null: false
    t.string "account_name", null: false
    t.string "generation", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "id = 1", name: "single_active_frame_io_connection"
  end

  create_table "frame_io_publications", force: :cascade do |t|
    t.string "account_id", null: false
    t.string "project_id", null: false
    t.string "file_id", null: false
    t.integer "realisation_id", null: false
    t.string "state", default: "pending", null: false
    t.string "source_sha256"
    t.text "session_url"
    t.string "review_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "project_id", "file_id"], name: "idx_on_account_id_project_id_file_id_84da1ec23e", unique: true
    t.index ["realisation_id"], name: "index_frame_io_publications_on_realisation_id", unique: true
    t.check_constraint "state IN ('pending', 'creating_session', 'uploading', 'completed', 'review')", name: "frame_io_publication_state"
  end

  create_table "frame_io_trials", force: :cascade do |t|
    t.string "account_id", null: false
    t.string "project_id", null: false
    t.json "existing_file_ids", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "project_id"], name: "index_frame_io_trials_on_account_id_and_project_id", unique: true
  end

  create_table "owner_invitations", force: :cascade do |t|
    t.string "provider", null: false
    t.string "code_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "redeemed_at"
    t.string "state_digest"
    t.boolean "state_used", default: false, null: false
    t.text "pending_adobe_grant"
    t.text "pkce_verifier"
    t.index ["code_digest"], name: "index_owner_invitations_on_code_digest", unique: true
    t.check_constraint "provider IN ('adobe', 'youtube')", name: "owner_invitation_provider"
  end

  create_table "realisations", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "position"
    t.string "youtube_id"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "legacy_source"
    t.string "legacy_id"
    t.string "legacy_vimeo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["legacy_source", "legacy_id"], name: "index_realisations_on_legacy_source_and_legacy_id", unique: true
    t.index ["published", "position"], name: "index_realisations_on_published_and_position"
  end

  create_table "youtube_connections", force: :cascade do |t|
    t.string "channel_id", null: false
    t.string "channel_title", null: false
    t.text "refresh_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "id = 1", name: "single_active_youtube_connection"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories_realisations", "categories"
  add_foreign_key "categories_realisations", "realisations"
  add_foreign_key "frame_io_publications", "realisations"
end
