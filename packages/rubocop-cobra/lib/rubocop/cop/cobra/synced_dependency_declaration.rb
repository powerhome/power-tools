# frozen_string_literal: true

require "digest"

module RuboCop
  module Cop
    module Cobra
      # Requires a component Gemfile's `path ".."` block to list exactly the
      # sibling components its gemspec declares, runtime and development
      # dependencies alike.
      #
      # A gemspec dependency counts as a sibling component when
      # `../<name>/<name>.gemspec` exists next to the component. Gemfiles with
      # no `path ".."` block are skipped, as are Gemfiles that don't call
      # `gemspec` or whose gemspec can't be found.
      #
      # The cop reads the gemspec beside the Gemfile, so RuboCop's cache only
      # notices a gemspec change when the component has its own `.rubocop.yml`.
      #
      # @safety
      #   Autocorrect inserts the missing `gem "<name>", require: nil` line in
      #   alphabetical order. Adding a gem changes `Gemfile.lock`, so it is
      #   unsafe: run `bundle install` afterwards. A gem in the block that the
      #   gemspec doesn't declare is not corrected, because only a person knows
      #   whether it is a runtime dependency, a development dependency, or
      #   unused.
      #
      # @example
      #   # my_component.gemspec
      #   s.add_dependency "directory", "0.0.1"
      #
      #   # bad
      #   path ".." do
      #     gem "nitro_react", require: nil
      #   end
      #
      #   # good
      #   path ".." do
      #     gem "directory", require: nil
      #   end
      #
      class SyncedDependencyDeclaration < RuboCop::Cop::Base
        extend AutoCorrector
        include ComponentGemfile
        include GemspecDependencies

        MISSING_MSG = "The `path \"..\"` block is missing components declared in `%<gemspec>s`: %<gems>s."
        UNDECLARED_MSG = "`%<gem>s` is in the `path \"..\"` block but not declared in `%<gemspec>s`. " \
                         "Declare it there, or remove it if this component doesn't use it directly."

        # @!method gemspec_call?(node)
        def_node_matcher :gemspec_call?, "(send nil? :gemspec ...)"

        def on_new_investigation
          return if processed_source.blank? || processed_source.file_path.nil?

          blocks = processed_source.ast.each_node(:block).select { |node| component_path_block?(node) }
          return if blocks.empty?

          gemspec = find_gemspec
          return if gemspec.nil?

          check(blocks, gemspec)
        end

        def external_dependency_checksum
          base = config.base_dir_for_path_parameters
          gemspecs = Dir[File.join(base, "*.gemspec")].map { |path| File.read(path) }
          siblings = Dir[File.join(base, "..", "*", "*.gemspec")]
          Digest::SHA1.hexdigest((gemspecs + siblings).join("\n"))
        end

      private

        def check(blocks, gemspec)
          declared = gemspec_dependency_names(gemspec.path)
          listed = blocks.flat_map { |block| gem_declarations(block).to_a }

          missing = missing_gems(declared, listed, gemspec)
          register_missing(blocks.first, missing, gemspec) if missing.any?
          listed.each { |node| register_undeclared(node, gemspec) unless declared.include?(gem_name(node)) }
        end

        def missing_gems(declared, listed, gemspec)
          siblings = declared.select { |name| gemspec.sibling_component?(name) }
          (siblings - listed.map { |node| gem_name(node) }).uniq.sort
        end

        def register_missing(block, names, gemspec)
          message = format(MISSING_MSG, gemspec: gemspec.file_name, gems: names.map { |name| "`#{name}`" }.join(", "))
          add_offense(block.send_node, message: message) do |corrector|
            PathBlockInsertion.new(block, processed_source.buffer).insert(corrector, names)
          end
        end

        def register_undeclared(node, gemspec)
          add_offense(node, message: format(UNDECLARED_MSG, gem: gem_name(node), gemspec: gemspec.file_name))
        end

        def find_gemspec
          call = processed_source.ast.each_node(:send).find { |node| gemspec_call?(node) }
          ComponentGemspec.for(processed_source.file_path, call) if call
        end

        def gem_name(node)
          node.first_argument.value
        end
      end
    end
  end
end
