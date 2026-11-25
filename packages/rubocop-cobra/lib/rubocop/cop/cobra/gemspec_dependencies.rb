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

      # @!method dependency_calls(node)
      def_node_search :dependency_calls, <<~PATTERN
        (send _ {:add_dependency :add_runtime_dependency :add_development_dependency} ...)
      PATTERN

      # The names of the dependencies declared in the gemspec at `path`, and
      # whether that list is complete. It isn't when the gemspec doesn't parse,
      # or declares a dependency whose name isn't a string literal (built in a
      # loop or splatted from a list, say).
      def gemspec_dependencies(path)
        ast = gemspec_ast(path)
        return [[], false] if ast.nil?

        readable = dependency_declarations(ast).to_a
        [readable.map { |node| node.first_argument.value }, readable.size == dependency_calls(ast).count]
      end

    private

      def gemspec_ast(path)
        source = ProcessedSource.from_file(path, processed_source.ruby_version,
                                           parser_engine: processed_source.parser_engine)
        source.ast if source.valid_syntax?
      end
    end
  end
end
