# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global presenters to the `app/presenters` directory.
      #
      # The goal is to encourage developers to put new presenters inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/presenters/foo_presenter.rb
      #   class FooPresenter
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/presenters/my_component/foo_presenter.rb
      #   module MyComponent
      #     class FooPresenter
      #       # ...
      #     end
      #   end
      #
      class PresenterFilePlacement < RuboCop::Cop::Cop
        include FilePlacementHelp

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, presenters_path)
          return if namespaced_correctly?(path, presenters_path)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, presenters_path))
        end

      private

        def presenters_path
          "app/presenters/"
        end
      end
    end
  end
end
