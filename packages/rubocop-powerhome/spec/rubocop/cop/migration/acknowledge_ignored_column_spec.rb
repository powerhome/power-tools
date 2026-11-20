# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Migration::AcknowledgeIgnoredColumn, :config do
  context "when `remove_column` is used" do
    it "registers an offense with remove_column" do
      expect_offense(<<~RUBY)
        class RemoveUsersSettings < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :settings
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not remove a column until it is already ignored in production and all references to it are removed. Once done, remove the 'ignored_columns' from the Model and disable this cop to acknowledge this is safe.
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
              ^^^^^^^^^^^^^^^^^^ Do not remove a column until it is already ignored in production and all references to it are removed. Once done, remove the 'ignored_columns' from the Model and disable this cop to acknowledge this is safe.
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

    it "does not register an offense in a down method" do
      expect_no_offenses(<<~RUBY)
        class Example < ActiveRecord::Migration[7.0]
          def up
            add_column :users, :settings, :string
          end

          def down
            remove_column :users, :settings
            change_table :users do |t|
              t.remove :settings
            end
          end
        end
      RUBY
    end

    it "does not register an offense in a reversible down block" do
      expect_no_offenses(<<~RUBY)
        class Example < ActiveRecord::Migration[7.0]
          def change
            reversible do |dir|
              dir.down { remove_column :users, :settings }
            end
          end
        end
      RUBY
    end
  end

  context "when other column removal methods are used" do
    let(:message) do
      "Do not remove a column until it is already ignored in production and all references to it " \
        "are removed. Once done, remove the 'ignored_columns' from the Model and disable this cop " \
        "to acknowledge this is safe."
    end

    [
      "remove_columns :users, :settings, :prefs",
      "remove_reference :users, :account",
      "remove_belongs_to :users, :account",
      "remove_timestamps :users",
    ].each do |call|
      it "registers an offense with #{call.split.first}" do
        expect_offense(<<~RUBY)
          class Example < ActiveRecord::Migration[7.0]
            def change
              #{call}
              #{'^' * call.length} #{message}
            end
          end
        RUBY
      end
    end

    [
      "t.remove_references :account",
      "t.remove_belongs_to :account",
      "t.remove_timestamps",
    ].each do |call|
      it "registers an offense with #{call.split.first} in change_table" do
        expect_offense(<<~RUBY)
          class Example < ActiveRecord::Migration[7.0]
            def change
              change_table :users do |t|
                #{call}
                #{'^' * call.length} #{message}
              end
            end
          end
        RUBY
      end
    end
  end
end
