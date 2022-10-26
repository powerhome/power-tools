# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      class DependencyVersion < RuboCop::Cop::Cop
        extend NodePattern::Macros

        MSG = "External component dependencies should be declared with a version"

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless path.end_with?(".gemspec")

          dependency_declarations(processed_source.ast).each do |dep|
            next if declares_version?(dep)

            add_offense(dep, message: MSG)
          end
        end

      private

        def_node_search :dependency_declarations, <<~PATTERN
          (send (lvar _) {:add_dependency :add_runtime_dependency :add_development_dependency} (str _) ...)
        PATTERN

        def declares_version?(node)
          node.first_argument != node.last_argument
        end
      end
    end
  end
end
