# This migration comes from two_percent (originally 20250418202830)
class CreateTwoPercentAlternateEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_alternate_emails do |t|
      t.string :email
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
