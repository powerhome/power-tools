# frozen_string_literal: true

class CreatePayrollGhosts < ActiveRecord::Migration[6.0]
  def change
    create_table :payroll_ghosts do |t|
      t.string :name

      t.timestamps
    end
  end
end
