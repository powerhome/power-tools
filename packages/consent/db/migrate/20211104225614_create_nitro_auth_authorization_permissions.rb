# frozen_string_literal: true

class CreateNitroAuthAuthorizationPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :nitro_auth_authorization_permissions do |t|
      t.string :subject, limit: 80
      t.string :action, limit: 80
      t.string :view, limit: 80
      t.integer :role_id

      t.timestamps
    end

    add_index :nitro_auth_authorization_permissions, :role_id
    add_index :nitro_auth_authorization_permissions, :subject
    add_index :nitro_auth_authorization_permissions, %i[subject action]
  end
end
