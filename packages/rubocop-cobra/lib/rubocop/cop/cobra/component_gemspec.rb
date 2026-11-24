# frozen_string_literal: true

module RuboCop
  module Cop
    # The gemspec a component Gemfile loads with `gemspec` (honoring its
    # `name:` and `path:` options), and the sibling components beside it.
    class ComponentGemspec
      # Returns nil when the gemspec can't be found, or when there are several
      # and the `gemspec` call doesn't name one.
      def self.for(gemfile_path, gemspec_call)
        gemfile_dir = File.dirname(File.expand_path(gemfile_path))
        options = string_options(gemspec_call)
        dir = File.expand_path(options.fetch("path", "."), gemfile_dir)
        candidates = Dir[File.join(dir, "#{options.fetch('name', '*')}.gemspec")]

        new(candidates.first, gemfile_dir) if candidates.one?
      end

      def self.string_options(call)
        return {} unless call.last_argument&.hash_type?

        call.last_argument.pairs.each_with_object({}) do |pair, options|
          options[pair.key.value.to_s] = pair.value.value if pair.key.sym_type? && pair.value.str_type?
        end
      end
      private_class_method :string_options

      attr_reader :path

      def initialize(path, gemfile_dir)
        @path = path
        @siblings_dir = File.expand_path("..", gemfile_dir)
      end

      def file_name
        File.basename(@path)
      end

      # True when `<siblings>/<name>/<name>.gemspec` exists for a component
      # other than this one.
      def sibling_component?(name)
        name != File.basename(@path, ".gemspec") && File.file?(File.join(@siblings_dir, name, "#{name}.gemspec"))
      end
    end
  end
end
