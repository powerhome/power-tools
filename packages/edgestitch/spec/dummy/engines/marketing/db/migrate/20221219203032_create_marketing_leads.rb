# frozen_string_literal: true

class CreateMarketingLeads < ActiveRecord::Migration[6.0]
  def change
    create_table :marketing_leads do |t|
      t.string :name

      t.timestamps
    end
  end
end
