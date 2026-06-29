# frozen_string_literal: true

class CreateTwoPercentScimGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :two_percent_scim_groups do |t|
      t.string :scim_id, null: false
      t.string :external_id, null: false
      t.string :display_name, null: false
      t.string :resource_type, null: false
      t.boolean :active, default: true
      t.text :scim_data, limit: 16_777_215 # MEDIUMTEXT for MySQL
      t.string :correlation_id

      t.timestamps

      t.index :scim_id, unique: true
      t.index %i[resource_type external_id], unique: true, name: "index_scim_groups_on_resource_and_external_id"
      t.index :resource_type
      t.index :active
      t.index :correlation_id
    end
  end
end
