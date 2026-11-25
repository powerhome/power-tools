# frozen_string_literal: true

module RuboCop
  module Cop
    # rubocop:disable-next Lint/RedundantCopDisableDirective
    module Migration
      # Do not remove columns until they are first ignored in production.
      # Covers remove_column(s), remove_reference/remove_belongs_to and
      # remove_timestamps, plus their change_table forms. Rolling back
      # (`def down`, `dir.down`) is not flagged.
      # Verify you have deleted the 'ignored_columns' from the Model and
      # then disable this cop to acknowledge.

      # @example
      #   # good BEFORE
      #   # This code is deployed to production
      #   class User < ApplicationRecord
      #     self.ignored_columns += %w[some_column]
      #   end
      #
      #   # good AFTER
      #   # Your changeset deletes the ignored_column
      #   class User < ApplicationRecord
      #   end

      #   class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :some_column # rubocop:disable Migration/AcknowledgeIgnoredColumn
      #     end
      #   end
      class AcknowledgeIgnoredColumn < RuboCop::Cop::Base
        include DownDirection

        MSG = "Do not remove a column until it is already ignored in production and " \
              "all references to it are removed. Once done, remove the 'ignored_columns' " \
              "from the Model and disable this cop to acknowledge this is safe."

        def on_send(node)
          return unless remove_column?(node)
          return if in_down_direction?(node)

          add_offense(node)
        end
        alias on_csend on_send

        def on_block(node)
          return unless change_table_block?(node)

          block_arg = node.arguments.first
          return unless block_arg

          remove_calls(node, block_arg.name) do |rename_node|
            next if in_down_direction?(rename_node)

            add_offense(rename_node)
          end
        end

        def_node_matcher :change_table_block?, <<~PATTERN
          (block
            (send nil? :change_table ...)
            (args (arg _))
            _
          )
        PATTERN

        def_node_search :remove_calls, <<~PATTERN
          (send
            (lvar %1)
            {:remove :remove_references :remove_belongs_to :remove_timestamps}
            ...
          )
        PATTERN

        def_node_matcher :remove_column?, <<~PATTERN
          (send
            nil?
            {:remove_column :remove_columns :remove_reference :remove_belongs_to :remove_timestamps}
            ...
          )
        PATTERN
      end
    end
  end
end
