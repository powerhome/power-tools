# This migration comes from two_percent (originally 20250418202857)
class CreateTwoPercentGroupMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_group_memberships do |t|
      t.belongs_to :user, null: false, foreign_key: false
      t.belongs_to :group, null: false, foreign_key: false

      t.timestamps
    end
  end
end
