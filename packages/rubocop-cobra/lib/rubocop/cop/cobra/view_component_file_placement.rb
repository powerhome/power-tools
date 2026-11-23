# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global view_components to the `app/components` directory.
      #
      # The goal is to encourage developers to put new view_components inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # The correct namespace is `app/components/my_component/resource/view_component.rb.
      # Similar to how `app/views` templates are nested in a directory named after the controller's resource.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/components/foo_component.rb
      #   class FooComponent < ::ViewComponent::Base
      #     # ...
      #   end
      #
      #   # bad
      #   # path: components/my_component/app/components/my_component/foo_component.rb
      #   module MyComponent
      #     class FooComponent < MyComponent::ApplicationComponent
      #       # ...
      #     end
      #   end
      #
      #   # acceptable
      #   # path: components/my_component/app/components/my_component/application_component.rb
      #   module MyComponent
      #     class ApplicationComponent < ::ViewComponent::Base
      #         # ...
      #       end
      #     end
      #   end
      #
      #   # good
      #   # path: components/my_component/app/components/my_component/resource/foo_component.rb
      #   module MyComponent
      #     module Resource
      #       class FooComponent < MyComponent::ApplicationComponent
      #         # ...
      #       end
      #     end
      #   end
      #
      class ViewComponentFilePlacement < RuboCop::Cop::Base
        include FilePlacementHelp

        FILE_PLACEMENT_MSG =
          "Nest ViewComponent definitions in the parent component and resource namespace. " \
          "For example: `%<correct_path>s`"

        def on_new_investigation
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, view_components_path)
          return if nested_in_resource?(path)

          add_offense(processed_source.ast,
                      message: format(FILE_PLACEMENT_MSG, correct_path: resource_path(path)))
        end

      private

        def view_components_path
          "app/components/"
        end

        def nested_in_resource?(path)
          match = component_path_match(path, view_components_path)
          component = match[:component]
          return false unless match[:rest].start_with?("#{component}/")

          sub_path = match[:rest].delete_prefix("#{component}/")
          sub_path.include?("/") || sub_path == "application_component.rb"
        end

        def resource_path(path)
          "#{view_components_path}#{component_name(path, view_components_path)}/<resource>/#{File.basename(path)}"
        end
      end
    end
  end
end
