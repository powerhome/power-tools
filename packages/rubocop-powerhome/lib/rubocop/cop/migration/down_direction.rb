# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Detects code that only runs when a migration is rolled back: a `down`
      # method, or a `dir.down` block inside `reversible`. Rollbacks undo an
      # earlier `up`, so the migration cops leave them alone.
      module DownDirection
        extend NodePattern::Macros

        def_node_matcher :down_block?, "(block (send lvar :down) ...)"

        def in_down_direction?(node)
          node.each_ancestor(:def, :defs, :block).any? do |ancestor|
            ancestor.block_type? ? down_block?(ancestor) : ancestor.method?(:down)
          end
        end
      end
    end
  end
end
