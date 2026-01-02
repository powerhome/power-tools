# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Do not rename columns that are in use.
      #
      # It will cause down time in your application.
      # Instead:
      #
      # 1. Create a new column
      # 2. Backfill and write to the new column
      # 3. Add old column to `ignored_columns` in model
      # 4. Drop the old column
      #
      # @safety
      #   Only meaningful if the table has records in it.
      #   But even if the column is not in use, you can not rename it.
      #   ActiveRecord accesses the old column unless queries explicitly SELECT other columns.
      #
      # @example
      #   # bad
      #   class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
      #     def change
      #       rename_column :users, :settings, :properties
      #     end
      #   end
      #
      #   # good
      #   class AddUsersProperties < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :properties, :jsonb
      #     end
      #   end
      #
      #   class User < ApplicationRecord
      #     self.ignored_columns += %w[settings]
      #   end
      #
      #   class RemoveUsersSettings < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :settings
      #     end
      #   end
      class RenameColumn < RuboCop::Cop::Base
        MSG = "Do not rename columns that are in use. It will cause down time in your application."

        def on_send(node)
          return unless rename_column?(node)

          add_offense(node)
        end
        alias on_csend on_send

        def_node_matcher :rename_column?, <<~PATTERN
          (send
            nil?
            :rename_column
            ...
          )
        PATTERN
      end
    end
  end
end
