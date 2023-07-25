# frozen_string_literal: true

class CreateAudiencesContexts < ActiveRecord::Migration[7.0]
  def change
    create_table :audiences_contexts do |t|
      t.references :owner, polymorphic: true, null: false
      t.boolean :match_all, default: false, null: false

      t.timestamps
    end
  end
end
