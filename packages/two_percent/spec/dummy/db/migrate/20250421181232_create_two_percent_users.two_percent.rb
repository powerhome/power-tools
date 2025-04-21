# This migration comes from two_percent (originally 20250417185348)
class CreateTwoPercentUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_users do |t|
      t.string :login
      t.integer :employee_number
      t.integer :account_id
      t.string :first_name
      t.string :last_name
      t.string :goes_by
      t.string :name
      t.string :primary_email
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :photo_url

      t.timestamps
    end
  end
end
