# frozen_string_literal: true

ActiveRecord::Schema.define do
  # Set up any tables you need to exist for your test suite that don't belong
  # in migrations.

  create_table :users, force: true do |t|
    # include columns sanitized by default
    t.string :encrypted_password
    t.string :ssn
    t.string :passport_number
    t.string :license_number
    t.date :date_of_birth
    t.date :dob
    t.text :notes
    t.text :body
    t.decimal :compensation, precision: 10, scale: 2
    t.decimal :income, precision: 10, scale: 2
    t.string :email
    t.string :email2
    t.string :address
    t.string :address2

    t.timestamps
  end

  # Mirror test_dump_schema extras so source (test_source) has the same tables sample! can copy from.
  create_table :cars, force: true do |t|
    t.string :make
    t.string :model
    t.integer :year
    t.string :color

    t.timestamps
  end

  create_table :dogs, force: true do |t|
    t.string :name
    t.string :breed
    t.integer :age

    t.timestamps
  end

  create_table :schema_migrations, force: true do |t|
    t.string :version, null: false
  end

  create_table "ar_internal_metadata", force: true, id: false do |t|
    t.string :key, null: false
    t.text :value
    t.timestamps
  end
end
