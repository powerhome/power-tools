# frozen_string_literal: true

class AddUniqueCompositeIndexToScimGroups < ActiveRecord::Migration[7.0]
  def change
    # Remove standalone external_id index
    remove_index :two_percent_scim_groups, :external_id, if_exists: true

    # Remove old non-unique composite index
    remove_index :two_percent_scim_groups,
                 %i[resource_type external_id],
                 name: "index_scim_groups_on_resource_and_external_id",
                 if_exists: true

    # Add new unique composite index
    add_index :two_percent_scim_groups,
              %i[resource_type external_id],
              unique: true,
              name: "index_scim_groups_on_resource_and_external_id",
              if_not_exists: true
  end
end
