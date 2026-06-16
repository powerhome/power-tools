# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Migration::RenameTable, :config do
  context "when `rename_table` is used" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class RenameUsersToAccouts < ActiveRecord::Migration[7.0]
          def change
            rename_table :users, :accounts
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not rename tables. It will cause down time in your application and is unsafe for pt-online-schema-change.
          end
        end
      RUBY
    end
  end
end
