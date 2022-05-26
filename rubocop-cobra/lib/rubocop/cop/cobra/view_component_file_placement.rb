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
      class ViewComponentFilePlacement < RuboCop::Cop::Cop
        FILE_PLACEMENT_MSG =
          "Nest ViewComponent definitions in the parent component and resource namespace. " \
          "For example: `%<correct_path>s`"

        def investigate(processed_source)
          return if processed_source.blank?
          return unless path_contains_matcher?
          return if namespaced_correctly?

          add_offense(processed_source.ast,
                      message: format(FILE_PLACEMENT_MSG, correct_path: correct_path))
        end

      private

        def view_components_path
          "app/components/"
        end

        def path
          @path ||= processed_source.file_path
        end

        def namespaced_correctly?
          potential_component_name = component_name
          component_path = File.join(
            potential_component_name,
            view_components_path,
            potential_component_name
          )
          return false unless path.include?("#{component_path}/")

          sub_path = path.split("#{component_path}/").last
          sub_path.include?("/") || sub_path == "application_component.rb"
        end

        def correct_path
          file = path.split("/").last
          "#{view_components_path}#{component_name}/<resource>/#{file}"
        end

        def component_name
          path.split(view_components_path).first.split("/").last
        end

        def path_contains_matcher?
          path.include?(view_components_path)
        end
      end
    end
  end
end
