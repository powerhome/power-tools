# frozen_string_literal: true

module RuboCop
  module Cop
    # The gemspec a component Gemfile loads with `gemspec` (honoring its
    # `name:` and `path:` options), and the sibling components beside it.
    class ComponentGemspec
      # @param gemfile [ProcessedSource] the Gemfile
      # @param gemspec_call [RuboCop::AST::SendNode] its `gemspec` call
      #
      # Returns nil when the gemspec can't be found, or when there are several
      # and the `gemspec` call doesn't name one. Like Bundler, `name:` is
      # matched against each gemspec's `name`, not its file name.
      def self.for(gemfile, gemspec_call)
        gemfile_dir = File.dirname(File.expand_path(gemfile.file_path))
        options = string_options(gemspec_call)
        dir = File.expand_path(options.fetch("path", "."), gemfile_dir)
        candidates = candidates(dir, options["name"], gemfile)

        new(candidates.first, gemfile_dir, options["name"]) if candidates.one?
      end

      def self.candidates(dir, name, gemfile)
        paths = Dir[File.join(dir, "*.gemspec")]
        name ? paths.select { |path| spec_name(path, gemfile) == name } : paths
      end
      private_class_method :candidates

      def self.string_options(call)
        return {} unless call.last_argument&.hash_type?

        call.last_argument.pairs.each_with_object({}) do |pair, options|
          options[pair.key.value.to_s] = pair.value.value if pair.key.sym_type? && pair.value.str_type?
        end
      end
      private_class_method :string_options

      # The string the gemspec assigns to `name`, or its file name when the
      # name isn't a string literal.
      def self.spec_name(path, gemfile)
        source = ProcessedSource.from_file(path, gemfile.ruby_version, parser_engine: gemfile.parser_engine)
        assignment = source.ast&.each_node(:send)&.find do |node|
          node.method?(:name=) && node.first_argument&.str_type?
        end
        assignment ? assignment.first_argument.value : File.basename(path, ".gemspec")
      end
      private_class_method :spec_name

      attr_reader :path

      def initialize(path, gemfile_dir, name = nil)
        @path = path
        @name = name || File.basename(path, ".gemspec")
        @siblings_dir = File.expand_path("..", gemfile_dir)
      end

      def file_name
        File.basename(@path)
      end

      # True when `<siblings>/<name>/<name>.gemspec` exists for a component
      # other than this one.
      def sibling_component?(name)
        name != @name && File.file?(File.join(@siblings_dir, name, "#{name}.gemspec"))
      end
    end
  end
end
