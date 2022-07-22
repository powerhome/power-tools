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
    t.integer :strength
    t.references :created_by
    t.references :created_by_department
    t.references :updated_by
    t.references :updated_by_department
  end

  create_table(:sales, force: true) do |t|
    t.integer :price
    t.references :created_by
    t.references :updated_by
  end

  create_table(:scores, force: true) do |t|
    t.integer :score
    t.references :created_by
    t.references :updated_by
  end

  create_table(:homes, force: true) do |t|
    t.integer :price
    t.references :created_by
    t.references :created_by_department
    t.references :updated_by
    t.references :updated_by_department
  end
end
