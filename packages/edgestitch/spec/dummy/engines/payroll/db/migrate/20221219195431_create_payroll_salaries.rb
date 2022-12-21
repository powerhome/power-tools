# frozen_string_literal: true

class CreatePayrollSalaries < ActiveRecord::Migration[6.0]
  def change
    create_table :payroll_salaries do |t|
      t.integer :value

      t.timestamps
    end
  end
end
