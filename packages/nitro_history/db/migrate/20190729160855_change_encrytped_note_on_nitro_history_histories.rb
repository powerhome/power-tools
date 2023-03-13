# frozen_string_literal: true

class ChangeEncrytpedNoteOnNitroHistoryHistories < ActiveRecord::Migration[5.1]
  def change
    change_column :nitro_history_histories, :encrypted_note, :text
  end
end
