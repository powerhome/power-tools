# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global helpers to the `app/mailers` directory.
      #
      # The goal is to encourage developers to put new mailer files inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/mailers/foo.rb
      #   class Foo
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/mailers/my_component/foo.rb
      #   module MyComponent
      #     class Foo
      #       # ...
      #     end
      #   end
      #
      class MailerFilePlacement < RuboCop::Cop::Cop
        include FilePlacementHelp

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, mailers_path)
          return if namespaced_correctly?(path, mailers_path)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, mailers_path))
        end

      private

        def mailers_path
          "app/mailers/"
        end
      end
    end
  end
end
