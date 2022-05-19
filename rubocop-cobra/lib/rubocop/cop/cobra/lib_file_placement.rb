# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding library files directly into the `lib/` directory.
      #
      # The goal is to encourage developers to put new library files inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # Exceptions to this rule are `spec/lib/*` and `lib/tasks/*` file patterns.
      #
      # @example
      #   # bad
      #   # path: components/my_component/lib/foo.rb
      #   class Foo
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/lib/my_component/foo.rb
      #   module MyComponent
      #     class Foo
      #       # ...
      #     end
      #   end
      #
      class LibFilePlacement < RuboCop::Cop::Cop
        include FilePlacementHelp

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, lib_path)
          return if acceptable_lib_path?(path) || namespaced_correctly?(path, lib_path)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, lib_path))
        end

      private

        def acceptable_lib_path?(path)
          path.include?("lib/tasks/") || path.include?("spec/lib/")
        end

        def lib_path
          "lib/"
        end
      end
    end
  end
end
