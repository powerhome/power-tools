# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global models to the `app/models` directory.
      #
      # The goal is to encourage developers to put new models inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/models/foo.rb
      #   class Foo < ApplicationRecord
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/models/my_component/foo.rb
      #   module MyComponent
      #     class Foo < MyComponent::ApplicationRecord
      #       # ...
      #     end
      #   end
      #
      class ModelFilePlacement < RuboCop::Cop::Base
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
          [model_concerns_path, models_path].find { |matcher| applicable_component_path?(path, matcher) }
        end

        def models_path
          "app/models/"
        end

        def model_concerns_path
          "app/models/concerns/"
        end
      end
    end
  end
end
