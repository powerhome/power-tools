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

ActiveRecord::Schema[8.0].define(version: 2025_04_21_170132) do
  create_table "two_percent_alternate_emails", force: :cascade do |t|
    t.string "email"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_two_percent_alternate_emails_on_user_id"
  end

  create_table "two_percent_group_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_two_percent_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_two_percent_group_memberships_on_user_id"
  end

  create_table "two_percent_groups", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "description"
    t.integer "group_number"
    t.string "type"
    t.string "abbr"
    t.boolean "mfa_setting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "two_percent_phone_numbers", force: :cascade do |t|
    t.string "number"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_two_percent_phone_numbers_on_user_id"
  end

  create_table "two_percent_users", force: :cascade do |t|
    t.string "login"
    t.integer "employee_number"
    t.integer "account_id"
    t.string "first_name"
    t.string "last_name"
    t.string "goes_by"
    t.string "name"
    t.string "primary_email"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "two_percent_alternate_emails", "users"
  add_foreign_key "two_percent_group_memberships", "groups"
  add_foreign_key "two_percent_group_memberships", "users"
  add_foreign_key "two_percent_phone_numbers", "users"
end
