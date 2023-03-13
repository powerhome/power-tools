# frozen_string_literal: true

class AddNoteToNitroHistoryHistories < ActiveRecord::Migration[4.2]
  def change
    add_column :nitro_history_histories, :note, :text
  end
end
