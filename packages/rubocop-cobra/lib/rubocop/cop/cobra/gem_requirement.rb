# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Requires gems declared in a component Gemfile's `path ".."` block to
      # specify `require: nil` (or `require: false`), so a component never
      # auto-requires its sibling components.
      #
      # The block may name the parent directory as `".."`, `"../"` or
      # `File.expand_path("..", __dir__)`, with or without other options such
      # as `glob:`.
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
        include ComponentGemfile

        MSG = "Component Gemfile dependencies must specify " \
              "'require: nil'."

        def on_block(node)
          return unless component_path_block?(node)

          gem_declarations(node).each do |gem_node|
            add_offense(gem_node) unless require_disabled?(gem_node)
          end
        end

        def_node_matcher :require_disabled?, <<~PATTERN
          (send nil? :gem (str _) ... (hash <(pair (sym :require) ({nil false})) ...>))
        PATTERN
      end
    end
  end
end
