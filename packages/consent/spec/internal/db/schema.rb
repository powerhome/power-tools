# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table(:example_models, force: true) do |t|
    t.string :name
    t.references :example_role
    t.references :additional_role

    t.timestamps
  end

  create_table :example_roles do |t|
    t.string :name
    t.references :example_department

    t.timestamps
  end

  create_table :example_departments do |t|
    t.string :name

    t.timestamps
  end
end
