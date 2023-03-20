# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
class CreateSimpleTrails < ActiveRecord::Migration[6.0]
  def change
    create_table :"#{SimpleTrail.table_name_prefix}histories" do |t|
      t.string :source_type
      t.string :source_id
      t.text :source_changes
      t.integer :user_id
      t.text :note
      t.string :activity
      t.text :encrypted_note
      t.text :backtrace
    end

    add_index :"#{SimpleTrail.table_name_prefix}histories", %i[source_type source_id]
  end
end
# rubocop:enable Metrics/MethodLength
