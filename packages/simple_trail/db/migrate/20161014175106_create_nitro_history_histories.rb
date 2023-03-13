# frozen_string_literal: true

class CreateNitroHistoryHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :nitro_history_histories do |t|
      t.string :source_type
      t.string :source_id
      t.text :source_changes

      t.datetime :created_at
    end

    add_index :nitro_history_histories, %i[source_type source_id]
  end
end
