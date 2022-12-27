# frozen_string_literal: true

class CreateSalesPrices < ActiveRecord::Migration[6.0]
  def change
    create_table :sales_prices do |t|
      t.integer :value

      t.timestamps
    end
  end
end
