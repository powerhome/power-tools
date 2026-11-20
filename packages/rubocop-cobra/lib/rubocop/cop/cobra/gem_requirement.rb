# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Requires gems declared in a component Gemfile's `path ".."` block to
      # specify `require: nil` (or `require: false`), so a component never
      # auto-requires its sibling components.
      #
      # @example
      #   # bad
      #   path ".." do
      #     gem "other_component"
      #   end
      #
      #   # good
      #   path ".." do
      #     gem "other_component", require: nil
      #   end
      #
      class GemRequirement < RuboCop::Cop::Base
        MSG = "Component Gemfile dependencies must specify " \
              "'require: nil'."

        def on_block(node)
          return unless component_path_block?(node)

          gem_declarations(node).each do |gem_node|
            add_offense(gem_node) unless require_disabled?(gem_node)
          end
        end

        def_node_matcher :component_path_block?, <<~PATTERN
          (block (send nil? :path (str "..")) (args) _)
        PATTERN

        def_node_search :gem_declarations, "(send nil? :gem (str _) ...)"

        def_node_matcher :require_disabled?, <<~PATTERN
          (send nil? :gem (str _) ... (hash <(pair (sym :require) ({nil false})) ...>))
        PATTERN
      end
    end
  end
end
