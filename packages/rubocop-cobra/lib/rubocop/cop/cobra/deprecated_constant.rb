# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Flags references to constants the application has deprecated, such as a
      # class left behind as a shim after it moved into another component.
      #
      # The cop never decides on its own what is deprecated. It does nothing
      # until the application lists each deprecated constant and its
      # replacement under `Constants`, and an entry is removed once the old
      # constant is deleted.
      #
      # Besides constant references, it flags the string forms (`class_name:`
      # and `constantize`) and associations whose class Rails infers from the
      # association name, since a constant search misses those and they break
      # once the old constant is deleted.
      #
      # Relative names are resolved the way Ruby or Rails would, so a bare
      # `Region` inside `module CoreModels` counts as `CoreModels::Region`. A
      # reference that already resolves to the replacement is left alone: a
      # bare `Territory` inside `module Directory`, or `belongs_to :territory`
      # in a model under `Directory`. In a concern the including model is not
      # known, so its associations are flagged whenever they could reach a
      # deprecated class. The deprecated class's own definition (the shim) is
      # not flagged, nor are associations in serializer or resource classes
      # (names ending in `Serializer` or `Resource`), whose DSLs share the
      # method names but take no `class_name:`.
      #
      # Association names are matched without regard to case, so one Rails
      # camelizes with an application acronym (`has_many :api_keys` to
      # `APIKey`) still matches the configured constant. Constants and strings
      # match exactly, as Ruby does, so `TERRITORY` is not `Territory`. Custom
      # irregular plurals are not read from the application.
      #
      # @safety
      #   Autocorrection is unsafe. While the deprecated class still defines
      #   behavior of its own, switching a caller to the replacement can
      #   change what that caller gets back.
      #
      #   The cop sees one file at a time. A relative name inside a namespace
      #   that defines its own class of the same name in another file (a bare
      #   `Territory` inside `module Sales`, where `Sales::Territory` exists)
      #   is flagged and would be rewritten to the replacement. Classes and
      #   constants defined in the same file are taken into account.
      #
      # @example Constants: { Territory: Directory::Territory }
      #   # bad
      #   Territory.find(id)
      #   ::Territory::STATUSES
      #   belongs_to :territory
      #   has_many :territories, class_name: "Territory"
      #   "Territory".constantize
      #
      #   # good
      #   Directory::Territory.find(id)
      #   ::Directory::Territory::STATUSES
      #   belongs_to :territory, class_name: "Directory::Territory"
      #   has_many :territories, class_name: "Directory::Territory"
      #   "Directory::Territory".constantize
      #
      #   module Directory
      #     class Branch < ApplicationRecord
      #       belongs_to :territory   # Rails finds Directory::Territory first
      #       Territory.find(id)      # Ruby finds Directory::Territory first
      #     end
      #   end
      class DeprecatedConstant < RuboCop::Cop::Base
        extend AutoCorrector
        include ConstantResolution
        include AssociationClass

        MSG = "Use `%<replacement>s` instead of the deprecated `%<deprecated>s`."
        ASSOCIATION_MSG = "`%<method>s :%<name>s` resolves to the deprecated `%<deprecated>s`. " \
                          "Name the replacement with `class_name: \"%<replacement>s\"`."

        RESTRICT_ON_SEND = %i[belongs_to has_one has_many has_and_belongs_to_many constantize safe_constantize].freeze

        def_node_matcher :association, <<~PATTERN
          (send nil? ${:belongs_to :has_one :has_many :has_and_belongs_to_many} (sym $_) ...)
        PATTERN

        def_node_matcher :constantized_string, "(send $(str $_) {:constantize :safe_constantize})"

        def_node_matcher :class_name_string, "(pair (sym :class_name) $(str $_))"

        def on_new_investigation
          super
          @known_constants = nil
        end

        def on_const(node)
          return if class_or_module_name?(node)

          name = node.source.gsub(/\s+/, "").delete_prefix("::")
          return unless deprecations.possibly_deprecated?(name)

          deprecated = deprecated_target(node.absolute? ? [name] : ruby_candidates(node, name))
          return unless deprecated

          replacement = deprecations.replacement_for(deprecated)
          register(node, deprecated, replacement) do |corrector|
            corrector.replace(node, node.absolute? ? "::#{replacement}" : replacement)
          end
        end

        def on_pair(node)
          class_name_string(node) do |string, value|
            name = value.delete_prefix("::")
            next unless deprecations.possibly_deprecated?(name)

            deprecated = value.start_with?("::") ? deprecated_target([name]) : rails_target(node, name)
            register_string(string, deprecated) if deprecated
          end
        end

        def on_send(node)
          constantized_string(node) do |string, value|
            deprecated = deprecated_target([value.delete_prefix("::")])
            register_string(string, deprecated) if deprecated
          end

          association(node) do |method, association_name|
            check_association(node, method, association_name) unless explicit_class?(node) || non_model_class?(node)
          end
        end

      private

        def check_association(node, method, association_name)
          name = inferred_class_name(method, association_name)
          return unless deprecations.possibly_deprecated?(name, ignore_case: true)

          deprecated = rails_target(node, name, ignore_case: true)
          return unless deprecated

          replacement = deprecations.replacement_for(deprecated)
          message = format(ASSOCIATION_MSG, method: method, name: association_name,
                                            deprecated: deprecated, replacement: replacement)
          add_offense(node, message: message) do |corrector|
            anchor = options(node)&.pairs&.last || node.last_argument
            corrector.insert_after(anchor, ", class_name: \"#{replacement}\"")
          end
        end

        # The deprecated constant a reference reaches, if any, given the full
        # names Ruby or Rails tries in order. A replacement, or a constant this
        # file defines, exists, so reaching one first means the reference is
        # already fine. Where the model is not known (a concern) any candidate
        # may be the one Rails picks, so every candidate is checked.
        def deprecated_target(candidates, stop_at_replacement: true, ignore_case: false)
          reached = candidates.find do |candidate|
            deprecations.deprecated(candidate, ignore_case: ignore_case) ||
              (stop_at_replacement && known_constant?(candidate, ignore_case: ignore_case))
          end
          reached && deprecations.deprecated(reached, ignore_case: ignore_case)
        end

        def rails_target(node, name, ignore_case: false)
          deprecated_target(rails_candidates(node, name),
                            stop_at_replacement: model_known?(node), ignore_case: ignore_case)
        end

        def known_constant?(name, ignore_case: false)
          known_constants.any? { |known| ignore_case ? known.casecmp?(name) : known == name }
        end

        def register(node, name, replacement, &block)
          add_offense(node, message: format(MSG, replacement: replacement, deprecated: name), &block)
        end

        def register_string(string, deprecated)
          replacement = deprecations.replacement_for(deprecated)
          prefix = "::" if string.value.start_with?("::")
          register(string, deprecated, replacement) do |corrector|
            corrector.replace(string, "#{string.loc.begin.source}#{prefix}#{replacement}#{string.loc.end.source}")
          end
        end

        def deprecations
          @deprecations ||= DeprecationList.new(cop_config["Constants"])
        end

        def known_constants
          @known_constants ||= deprecations.replacements + defined_constants(processed_source.ast)
        end

        # The name being defined by `class X` or `module X` is not a use of X.
        def class_or_module_name?(node)
          parent = node.parent
          parent&.type?(:class, :module) && parent.identifier.equal?(node)
        end
      end
    end
  end
end
