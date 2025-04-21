# This migration comes from two_percent (originally 20250418202816)
class CreateTwoPercentPhoneNumbers < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_phone_numbers do |t|
      t.string :number
      t.belongs_to :user, null: false, foreign_key: false

      t.timestamps
    end
  end
end
