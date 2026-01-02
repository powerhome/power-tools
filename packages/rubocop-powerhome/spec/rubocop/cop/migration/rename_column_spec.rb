# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Migration::RenameColumn, :config do
  context "when `rename_column` is used" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
          def change
            rename_column :users, :settings, :properties
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not rename columns that are in use. It will cause down time in your application and is unsafe for pt-online-schema-change.
          end
        end
      RUBY
    end
  end
end
