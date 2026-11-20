# frozen_string_literal: true

module RuboCop
  module Cop
    # Methods that help analyzing file placement within Nitro components
    module FilePlacementHelp
      FILE_PLACEMENT_MSG =
        "Do not add top-level files into `%<matcher_path>s`. " \
        "Namespace them like `%<correct_path>s`"

      # True when the file lives in `components/<component>/<matcher>`. The
      # matcher must sit directly under a component's root, so a `lib/` or
      # `components/` elsewhere in the path (a parent directory, a component
      # named `pdf_lib`, `app/lib/`) does not count.
      def applicable_component_path?(path, matcher)
        !component_path_match(path, matcher).nil?
      end

      def namespaced_correctly?(path, matcher)
        match = component_path_match(path, matcher)
        component = match[:component]

        match[:rest].start_with?("#{component}/") || match[:rest] == "#{component}.rb"
      end

      def file_placement_msg(path, matcher)
        format(FILE_PLACEMENT_MSG,
               matcher_path: matcher,
               correct_path: correct_path(path, matcher))
      end

    private

      def correct_path(path, matcher)
        match = component_path_match(path, matcher)
        "#{matcher}#{match[:component]}/#{match[:rest]}"
      end

      def component_name(path, matcher)
        component_path_match(path, matcher)[:component]
      end

      def component_path_match(path, matcher)
        %r{\A(?:.*/)?components/(?<component>[^/]+)/#{Regexp.escape(matcher)}(?<rest>.+)\z}.match(path)
      end
    end
  end
end
