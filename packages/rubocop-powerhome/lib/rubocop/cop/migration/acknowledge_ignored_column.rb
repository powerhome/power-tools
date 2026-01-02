# frozen_string_literal: true

module RuboCop
  module Cop
    # rubocop:disable Lint/RedundantCopDisableDirective
    module Migration
      # Do not remove columns until they are first ignored in production.
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
        MSG = "Do not remove columns until they are first ignored in production. " \
              "Verify you have deleted the 'ignored_columns' from the Model and " \
              "then disable this cop to acknowledge."

        def on_send(node)
          return unless remove_column?(node)

          add_offense(node)
        end
        alias on_csend on_send

        def on_block(node)
          return unless change_table_block?(node)

          block_arg = node.arguments.first
          return unless block_arg

          remove_calls(node, block_arg.name) do |rename_node|
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
            :remove
            ...
          )
        PATTERN

        def_node_matcher :remove_column?, <<~PATTERN
          (send
            nil?
            :remove_column
            ...
          )
        PATTERN
      end
    end
    # rubocop:enable Lint/RedundantCopDisableDirective
  end
end
