# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Do not rename columns that are in use. It will cause down time in your application
      # and is unsafe for pt-online-schema-change.
      # Instead:
      #
      # 1. Create a new column
      # 2. Backfill and write to the new column
      # 3. Add old column to `ignored_columns` in model
      # 4. Drop the old column
      #
      # This is meaningful if the table has records in it.
      # But even if the column is not in use, one can not rename it.
      # ActiveRecord accesses old columns unless all queries explicitly SELECT other columns.
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
        MSG = "Do not rename columns that are in use. It will cause down time in your application " \
              "and is unsafe for pt-online-schema-change."

        def on_send(node)
          return unless rename_column?(node)

          add_offense(node)
        end
        alias on_csend on_send

        def on_block(node)
          return unless change_table_block?(node)

          block_arg = node.arguments.first
          return unless block_arg

          rename_calls(node, block_arg.name) do |rename_node|
            add_offense(rename_node)
          end
        end

        private

        def_node_matcher :change_table_block?, <<~PATTERN
          (block
            (send nil? :change_table ...)
            (args (arg _))
            _
          )
        PATTERN

        def_node_search :rename_calls, <<~PATTERN
          (send
            (lvar %1)
            :rename
            ...
          )
        PATTERN

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
