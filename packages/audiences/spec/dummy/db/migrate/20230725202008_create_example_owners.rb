# frozen_string_literal: true

class CreateExampleOwners < ActiveRecord::Migration[6.0]
  def change
    create_table :example_owners do |t|
      t.string :name

      t.timestamps
    end
  end
end
