# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table(:departments, force: true) do |t|
    t.string :name
  end

  create_table(:users, force: true) do |t|
    t.string :name
    t.references :department
  end

  create_table(:leads, force: true) do |t|
    t.references :created_by
    t.references :created_by_department
    t.references :updated_by
    t.references :updated_by_department
  end

  create_table(:sales, force: true) do |t|
    t.references :created_by
    t.references :updated_by
  end
end
