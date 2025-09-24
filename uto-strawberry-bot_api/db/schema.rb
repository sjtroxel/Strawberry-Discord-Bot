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

ActiveRecord::Schema[8.0].define(version: 2025_09_24_154122) do
  create_table "eowcf_records", force: :cascade do |t|
    t.integer "kingdom_id", null: false
    t.string "loc"
    t.datetime "eowcf_start"
    t.datetime "eowcf_end"
    t.datetime "detected_at"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kingdom_id"], name: "index_eowcf_records_on_kingdom_id"
  end

  create_table "kingdom_snapshots", force: :cascade do |t|
    t.integer "kingdom_id", null: false
    t.string "loc"
    t.datetime "snapshot_time"
    t.integer "total_land"
    t.integer "total_honor"
    t.json "provinces", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kingdom_id"], name: "index_kingdom_snapshots_on_kingdom_id"
  end

  create_table "kingdoms", force: :cascade do |t|
    t.string "loc"
    t.string "name"
    t.string "stance"
    t.integer "honor"
    t.integer "nw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provinces", force: :cascade do |t|
    t.integer "kingdom_id", null: false
    t.string "loc"
    t.string "name"
    t.integer "land"
    t.string "race"
    t.integer "honor"
    t.integer "nw"
    t.boolean "protected"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kingdom_id"], name: "index_provinces_on_kingdom_id"
  end

  add_foreign_key "eowcf_records", "kingdoms"
  add_foreign_key "kingdom_snapshots", "kingdoms"
  add_foreign_key "provinces", "kingdoms"
end
