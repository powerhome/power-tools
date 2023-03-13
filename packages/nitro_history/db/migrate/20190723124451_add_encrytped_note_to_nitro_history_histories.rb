# frozen_string_literal: true

class AddEncrytpedNoteToNitroHistoryHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :nitro_history_histories, :encrypted_note, :string
  end
end
