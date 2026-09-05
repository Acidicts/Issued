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

ActiveRecord::Schema[8.1].define(version: 2026_09_04_220457) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "balance_events", force: :cascade do |t|
    t.integer "amount"
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "initiator_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["initiator_id"], name: "index_balance_events_on_initiator_id"
    t.index ["user_id"], name: "index_balance_events_on_user_id"
  end

  create_table "designs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", default: ""
    t.string "hackatime_project"
    t.integer "hackatime_seconds"
    t.string "name", default: "Untitled Design", null: false
    t.integer "status"
    t.integer "time"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["hackatime_project"], name: "index_designs_on_hackatime_project", unique: true
    t.index ["name"], name: "index_designs_on_name"
    t.index ["user_id"], name: "index_designs_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.datetime "from_time"
    t.datetime "updated_at", null: false
    t.index ["design_id"], name: "index_images_on_design_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "kind"
    t.integer "priority"
    t.boolean "read"
    t.string "time"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "order_print_areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.integer "design_image_num", default: 0
    t.string "name", default: ""
    t.bigint "order_id", null: false
    t.integer "rotation"
    t.datetime "updated_at", null: false
    t.integer "x"
    t.integer "xw"
    t.integer "y"
    t.integer "yw"
    t.index ["design_id"], name: "index_order_print_areas_on_design_id"
    t.index ["order_id"], name: "index_order_print_areas_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "color_hex"
    t.datetime "created_at", null: false
    t.jsonb "print_areas", default: {}, null: false
    t.bigint "product_id", null: false
    t.integer "status"
    t.integer "step"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "print_areas", force: :cascade do |t|
    t.float "cost"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false
    t.integer "image_wx"
    t.integer "image_wy"
    t.integer "image_x"
    t.integer "image_y"
    t.string "name"
    t.bigint "product_id", null: false
    t.integer "thread_cost"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_print_areas_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled"
    t.integer "image_wx", default: 0, null: false
    t.integer "image_wy", default: 0, null: false
    t.integer "image_x", default: 0, null: false
    t.integer "image_y", default: 0, null: false
    t.integer "printful_id"
    t.integer "thread_cost", default: 0
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "rsvps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_rsvps_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "credits"
    t.string "email"
    t.boolean "guide", default: false, null: false
    t.text "hackclub_access_token"
    t.text "hackclub_refresh_token"
    t.string "name"
    t.integer "role"
    t.string "slack_id"
    t.integer "threads"
    t.datetime "updated_at", null: false
    t.integer "veri_level"
    t.boolean "ysws_eligible", default: false, null: false
  end

  create_table "variants", force: :cascade do |t|
    t.string "color_hex"
    t.integer "cost"
    t.datetime "created_at", null: false
    t.integer "printful_id"
    t.bigint "product_id", null: false
    t.integer "size"
    t.jsonb "stock_by_region", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["stock_by_region"], name: "index_variants_on_stock_by_region", using: :gin
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "balance_events", "users"
  add_foreign_key "balance_events", "users", column: "initiator_id"
  add_foreign_key "designs", "users"
  add_foreign_key "images", "designs"
  add_foreign_key "notifications", "users"
  add_foreign_key "order_print_areas", "designs"
  add_foreign_key "order_print_areas", "orders"
  add_foreign_key "orders", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "print_areas", "products"
  add_foreign_key "rsvps", "users"
  add_foreign_key "variants", "products"
end
