class CreateTwoPercentGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :two_percent_groups do |t|
      t.string :code
      t.string :name
      t.string :description
      t.integer :group_number
      t.string :type
      t.string :abbr
      t.boolean :mfa_setting

      t.timestamps
    end
  end
end
