# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global helpers to the `app/commands` directory.
      #
      # The goal is to encourage developers to put new command files inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/commands/foo.rb
      #   class Foo
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/commands/my_component/foo.rb
      #   module MyComponent
      #     class Foo
      #       # ...
      #     end
      #   end
      #
      class CommandFilePlacement < RuboCop::Cop::Cop
        include FilePlacementHelp

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, commands_path)
          return if namespaced_correctly?(path, commands_path)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, commands_path))
        end

      private

        def commands_path
          "app/commands/"
        end
      end
    end
  end
end
