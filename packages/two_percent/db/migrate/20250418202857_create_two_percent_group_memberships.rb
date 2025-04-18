class CreateTwoPercentGroupMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
