# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global controllers to the `app/controllers` directory.
      #
      # The goal is to encourage developers to put new controllers inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/controllers/foo_controller.rb
      #   class FooController < ApplicationController
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/controllers/my_component/foo_controller.rb
      #   module MyComponent
      #     class FooController < MyComponent::ApplicationController
      #       # ...
      #     end
      #   end
      #
      class ControllerFilePlacement < RuboCop::Cop::Base
        include FilePlacementHelp

        def on_new_investigation
          return if processed_source.blank?

          path = processed_source.file_path
          matcher = matcher_for(path)
          return unless matcher
          return if namespaced_correctly?(path, matcher)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, matcher))
        end

      private

        def matcher_for(path)
          [controller_concerns_path, controllers_path].find { |matcher| applicable_component_path?(path, matcher) }
        end

        def controllers_path
          "app/controllers/"
        end

        def controller_concerns_path
          "app/controllers/concerns/"
        end
      end
    end
  end
end
