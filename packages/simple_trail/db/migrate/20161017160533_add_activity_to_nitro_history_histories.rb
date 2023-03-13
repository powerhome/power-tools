# frozen_string_literal: true

class AddActivityToNitroHistoryHistories < ActiveRecord::Migration[4.2]
  def change
    add_column :nitro_history_histories, :activity, :string
  end
end
