# frozen_string_literal: true

class AddBacktraceToNitroHistoryHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :nitro_history_histories, :backtrace, :text
  end
end
