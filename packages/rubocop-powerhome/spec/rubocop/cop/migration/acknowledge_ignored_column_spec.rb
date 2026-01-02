# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Migration::AcknowledgeIgnoredColumn, :config do
  context "when `remove_column` is used" do
    it "registers an offense with remove_column" do
      expect_offense(<<~RUBY)
        class RemoveUsersSettings < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :settings
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not remove columns until they are first ignored in production. Verify you have deleted the 'ignored_columns' from the Model and then disable this cop to acknowledge.
          end
        end
      RUBY
    end

    it "registers an offense with remove in change_table" do
      expect_offense(<<~RUBY)
        class RemoveUsersSettings < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.remove :settings
              ^^^^^^^^^^^^^^^^^^ Do not remove columns until they are first ignored in production. Verify you have deleted the 'ignored_columns' from the Model and then disable this cop to acknowledge.
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

    it "does not register offenses when disabling acknowledgement" do
      expect_no_offenses(<<~RUBY)
        class ModifyUsers < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.remove :settings # rubocop:disable Migration/AcknowledgeIgnoredColumn
            end
          end
        end
      RUBY
    end
  end
end
