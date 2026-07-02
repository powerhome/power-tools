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

ActiveRecord::Schema[8.1].define(version: 2026_07_02_000002) do
  create_table "two_percent_scim_group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "scim_group_id", null: false
    t.integer "scim_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["scim_group_id"], name: "index_two_percent_scim_group_memberships_on_scim_group_id"
    t.index ["scim_user_id", "scim_group_id"], name: "index_scim_memberships_on_user_and_group", unique: true
    t.index ["scim_user_id"], name: "index_two_percent_scim_group_memberships_on_scim_user_id"
  end

  create_table "two_percent_scim_groups", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "external_id", null: false
    t.string "resource_type", null: false
    t.text "scim_data", limit: 16777215
    t.string "scim_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_two_percent_scim_groups_on_active"
    t.index ["correlation_id"], name: "index_two_percent_scim_groups_on_correlation_id"
    t.index ["resource_type", "external_id"], name: "index_scim_groups_on_resource_and_external_id", unique: true
    t.index ["resource_type"], name: "index_two_percent_scim_groups_on_resource_type"
    t.index ["scim_id"], name: "index_two_percent_scim_groups_on_scim_id", unique: true
  end

  create_table "two_percent_scim_users", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "external_id", null: false
    t.text "scim_data", limit: 16777215
    t.string "scim_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_name"
    t.index ["active"], name: "index_two_percent_scim_users_on_active"
    t.index ["correlation_id"], name: "index_two_percent_scim_users_on_correlation_id"
    t.index ["email"], name: "index_two_percent_scim_users_on_email"
    t.index ["external_id"], name: "index_two_percent_scim_users_on_external_id", unique: true
    t.index ["scim_id"], name: "index_two_percent_scim_users_on_scim_id", unique: true
    t.index ["user_name"], name: "index_two_percent_scim_users_on_user_name"
  end
end
