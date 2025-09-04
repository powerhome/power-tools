# frozen_string_literal: true

ActiveRecord::Schema.define do
  # Set up any tables you need to exist for your test suite that don't belong
  # in migrations.

  create_table :users, force: true do |t|
    t.string :email
    t.string :ssn
    t.date :date_of_birth
    t.text :notes
    t.decimal :compensation, precision: 10, scale: 2
    t.string :encrypted_password
    t.string :email2
    t.string :address
    t.string :address2
    t.string :passport_number
    t.string :license_number
    t.date :dob
    t.text :body
    t.decimal :income, precision: 10, scale: 2

    t.timestamps
  end
end
