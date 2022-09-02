# frozen_string_literal: true

class CreateNitroAuthAuthorizationPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :"#{Consent.table_name_prefix}permissions" do |t|
      t.string :subject, limit: 80
      t.string :action, limit: 80
      t.string :view, limit: 80
      t.integer :role_id

      t.timestamps
    end

    add_index :"#{Consent.table_name_prefix}permissions", :role_id
    add_index :"#{Consent.table_name_prefix}permissions", :subject
    add_index :"#{Consent.table_name_prefix}permissions", %i[subject action],
              name: :"idx_#{Consent.table_name_prefix}permissions_on_subject_and_action"
  end
end
