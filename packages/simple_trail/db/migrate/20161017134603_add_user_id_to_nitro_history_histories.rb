# frozen_string_literal: true

class AddUserIdToNitroHistoryHistories < ActiveRecord::Migration[4.2]
  def change
    add_column :nitro_history_histories, :user_id, :integer
  end
end
