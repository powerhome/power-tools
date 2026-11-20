# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Detects code that only runs when a migration is rolled back: a `down`
      # method, or a `dir.down` block inside `reversible do |dir|`. Rollbacks
      # undo an earlier `up`, so the migration cops leave them alone.
      module DownDirection
        extend NodePattern::Macros

        def_node_matcher :down_block_receiver, "(block (send (lvar $_) :down) ...)"
        def_node_matcher :reversible_block_arg, "(block (send nil? :reversible) (args (arg $_)) _)"

        def in_down_direction?(node)
          node.each_ancestor(:def, :defs, :block).any? do |ancestor|
            ancestor.block_type? ? reversible_down_block?(ancestor) : ancestor.method?(:down)
          end
        end

      private

        def reversible_down_block?(block)
          receiver = down_block_receiver(block)
          return false unless receiver

          block.each_ancestor(:block).any? { |outer| reversible_block_arg(outer) == receiver }
        end
      end
    end
  end
end
