# frozen_string_literal: true

module RuboCop
  module Cop
    # Methods that help analyzing file placement within Nitro components
    module FilePlacementHelp
      FILE_PLACEMENT_MSG =
        "Do not add top-level files into `%<matcher_path>s`. " \
        "Namespace them like `%<correct_path>s`"

      def applicable_component_path?(path, matcher)
        in_a_component?(path) && path_contains_matcher?(path, matcher)
      end

      def namespaced_correctly?(path, matcher)
        potential_component_name = component_name(path, matcher)
        component_path = File.join(
          potential_component_name,
          matcher,
          potential_component_name
        )
        path.include?("#{component_path}/") || path.include?("#{component_path}.rb")
      end

      def file_placement_msg(path, matcher)
        format(FILE_PLACEMENT_MSG,
               matcher_path: matcher,
               correct_path: correct_path(path, matcher))
      end

    private

      def correct_path(path, matcher)
        file = path.split(matcher).last
        "#{matcher}#{component_name(path, matcher)}/#{file}"
      end

      def component_name(path, matcher)
        path.split(matcher).first.split("/").last
      end

      def in_a_component?(path)
        path.include?("components/")
      end

      def path_contains_matcher?(path, matcher)
        path.include?(matcher)
      end
    end
  end
end
