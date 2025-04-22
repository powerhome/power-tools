# frozen_string_literal: true

class AddUniquenessIndexToGroupMembership < ActiveRecord::Migration[8.0]
  def change
    add_index :two_percent_group_memberships, %i[group_id user_id], unique: true
  end
end
