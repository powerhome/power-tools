# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Migration::RenameColumn, :config do
  context "when `rename_column` is used" do
    it "registers an offense with rename_column" do
      expect_offense(<<~RUBY)
        class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
          def change
            rename_column :users, :settings, :properties
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not rename columns that are in use. It will cause down time in your application and is unsafe for pt-online-schema-change.
          end
        end
      RUBY
    end

    it "registers an offense with rename in change_table" do
      expect_offense(<<~RUBY)
        class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.rename :settings, :properties
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not rename columns that are in use. It will cause down time in your application and is unsafe for pt-online-schema-change.
            end
          end
        end
      RUBY
    end

    it "does not register offenses with normal change_table operations" do
      expect_no_offenses(<<~RUBY)
        class ModifyUsers < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.string :foo
              t.integer :bar
              t.remove_index name: "qux"
              t.change :dag, :decimal, precision: 6, scale: 4
            end
          end
        end
      RUBY
    end
  end
end
