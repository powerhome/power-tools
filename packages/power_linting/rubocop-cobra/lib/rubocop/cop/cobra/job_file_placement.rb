# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # This cop disallows adding global jobs to the `app/jobs` directory.
      #
      # The goal is to encourage developers to put new jobs inside the correct
      # namespace, where they can be more modularly isolated and ownership is clear.
      #
      # @example
      #   # bad
      #   # path: components/my_component/app/jobs/foo_job.rb
      #   class FooJob
      #     # ...
      #   end
      #
      #   # good
      #   # path: components/my_component/app/jobs/my_component/foo_job.rb
      #   module MyComponent
      #     class FooJob
      #       # ...
      #     end
      #   end
      #
      class JobFilePlacement < RuboCop::Cop::Cop
        include FilePlacementHelp

        def investigate(processed_source)
          return if processed_source.blank?

          path = processed_source.file_path
          return unless applicable_component_path?(path, jobs_path)
          return if namespaced_correctly?(path, jobs_path)

          add_offense(processed_source.ast,
                      message: file_placement_msg(path, jobs_path))
        end

      private

        def jobs_path
          "app/jobs/"
        end
      end
    end
  end
end
