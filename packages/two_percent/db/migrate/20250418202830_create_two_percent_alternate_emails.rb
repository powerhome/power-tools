# frozen_string_literal: true

class CreateTwoPercentAlternateEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :two_percent_alternate_emails do |t|
      t.string :email
      t.belongs_to :user, null: false, foreign_key: false

      t.timestamps
    end
  end
end
