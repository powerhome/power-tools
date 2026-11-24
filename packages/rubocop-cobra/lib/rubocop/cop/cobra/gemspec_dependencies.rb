# frozen_string_literal: true

module RuboCop
  module Cop
    # Node matchers for the dependencies a gemspec declares with
    # `add_dependency`, `add_runtime_dependency` or
    # `add_development_dependency`.
    module GemspecDependencies
      extend NodePattern::Macros

      # @!method dependency_declarations(node)
      def_node_search :dependency_declarations, <<~PATTERN
        (send (lvar _) {:add_dependency :add_runtime_dependency :add_development_dependency} (str _) ...)
      PATTERN

      # The names of every dependency declared in the gemspec at `path`.
      def gemspec_dependency_names(path)
        source = ProcessedSource.from_file(path, processed_source.ruby_version,
                                           parser_engine: processed_source.parser_engine)
        return [] unless source.valid_syntax? && source.ast

        dependency_declarations(source.ast).map { |node| node.first_argument.value }
      end
    end
  end
end
