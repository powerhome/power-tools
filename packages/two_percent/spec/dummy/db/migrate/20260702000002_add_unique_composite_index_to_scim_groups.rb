# frozen_string_literal: true

class AddUniqueCompositeIndexToScimGroups < ActiveRecord::Migration[7.0]
  def change
    add_index :two_percent_scim_groups,
              %i[resource_type external_id],
              unique: true,
              name: "index_scim_groups_on_resource_and_external_id",
              if_not_exists: true
  end
end
