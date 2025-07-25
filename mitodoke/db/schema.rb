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

ActiveRecord::Schema[7.2].define(version: 2025_07_01_125738) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "evidences", force: :cascade do |t|
    t.bigint "promise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promise_id"], name: "index_evidences_on_promise_id"
  end

  create_table "guests", force: :cascade do |t|
    t.string "family_name", null: false
    t.string "given_name", null: false
    t.string "handle_name"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_guests_on_email", unique: true
    t.index ["handle_name"], name: "index_guests_on_handle_name", unique: true
  end

  create_table "promise_participants", force: :cascade do |t|
    t.bigint "promise_id"
    t.bigint "guest_id"
    t.integer "role", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_promise_participants_on_guest_id"
    t.index ["promise_id"], name: "index_promise_participants_on_promise_id"
    t.index ["token"], name: "index_promise_participants_on_token", unique: true
  end

  create_table "promises", force: :cascade do |t|
    t.text "content"
    t.datetime "deadline"
    t.text "penalty"
    t.integer "progress"
    t.integer "status"
    t.datetime "accepted_at"
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.datetime "witnessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "completed_by"
    t.string "cancel_requested_by"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "evidences", "promises"
  add_foreign_key "promise_participants", "guests"
  add_foreign_key "promise_participants", "promises"
end
