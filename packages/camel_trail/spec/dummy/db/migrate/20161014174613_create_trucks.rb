# frozen_string_literal: true

class CreateTrucks < ActiveRecord::Migration[5.1]
  def change
    create_table :trucks do |t|
      t.string :name
      t.integer :price

      t.timestamps
    end
  end
end
