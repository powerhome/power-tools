# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Requires every gemspec dependency to declare a version requirement.
      #
      # @example
      #   # bad
      #   spec.add_dependency "some_lib"
      #
      #   # good
      #   spec.add_dependency "some_lib", "1.0.1"
      #
      class DependencyVersion < RuboCop::Cop::Base
        include GemspecDependencies

        MSG = "Gemspec dependencies should be declared with a version"

        def on_new_investigation
          return if processed_source.blank?

          path = processed_source.file_path
          return unless path.end_with?(".gemspec")

          dependency_declarations(processed_source.ast).each do |dep|
            next if declares_version?(dep)

            add_offense(dep, message: MSG)
          end
        end

      private

        def declares_version?(node)
          node.first_argument != node.last_argument
        end
      end
    end
  end
end
