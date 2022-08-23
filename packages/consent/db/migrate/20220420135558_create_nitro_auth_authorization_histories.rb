# frozen_string_literal: true

class CreateNitroAuthAuthorizationHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :nitro_auth_authorization_histories do |t|
      t.string :command, limit: 6
      t.string :subject, limit: 80
      t.string :action, limit: 80
      t.string :view, limit: 80
      t.integer :role_id

      t.timestamps
    end
  end
end
