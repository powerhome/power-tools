# frozen_string_literal: true

class CreateTrailHookVehicles < ActiveRecord::Migration[6.1]
  def change
    create_table :trail_hook_vehicles do |t|
      t.string :name
      t.integer :price
      t.string :activity
      t.text :note

      t.timestamps
    end
  end
end
