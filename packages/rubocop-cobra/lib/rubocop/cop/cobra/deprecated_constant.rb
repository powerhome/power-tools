# frozen_string_literal: true

require "active_support/inflector"

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
      # A reference that Ruby or Rails already resolves to the replacement is
      # left alone: a bare `Territory` inside `module Directory`, or
      # `belongs_to :territory` in a model under `Directory`. The deprecated
      # class's own definition (the shim) is not flagged either.
      #
      # @safety
      #   Autocorrection is unsafe. While the deprecated class still defines
      #   behavior of its own, switching a caller to the replacement can
      #   change what that caller gets back.
      #
      # @example Constants: { Territory: Directory::Territory }
      #   # bad
      #   Territory.find(id)
      #   ::Territory::STATUSES
      #   belongs_to :territory
      #   has_many :regions, class_name: "Territory"
      #   "Territory".constantize
      #
      #   # good
      #   Directory::Territory.find(id)
      #   ::Directory::Territory::STATUSES
      #   belongs_to :territory, class_name: "Directory::Territory"
      #   has_many :regions, class_name: "Directory::Territory"
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

        MSG = "Use `%<replacement>s` instead of the deprecated `%<deprecated>s`."
        ASSOCIATION_MSG = "`%<method>s :%<name>s` resolves to the deprecated `%<deprecated>s`. " \
                          "Name the replacement with `class_name: \"%<replacement>s\"`."

        COLLECTION_ASSOCIATIONS = %i[has_many has_and_belongs_to_many].freeze
        RESTRICT_ON_SEND = %i[belongs_to has_one has_many has_and_belongs_to_many constantize safe_constantize].freeze

        def_node_matcher :association, <<~PATTERN
          (send nil? ${:belongs_to :has_one :has_many :has_and_belongs_to_many} (sym $_) ...)
        PATTERN

        def_node_matcher :constantized_string, "(send $(str $_) {:constantize :safe_constantize})"

        def_node_matcher :class_name_string, "(pair (sym :class_name) $(str $_))"

        def on_const(node)
          return if class_or_module_name?(node)

          name = node.source.gsub(/\s+/, "").delete_prefix("::")
          replacement = deprecated_constants[name]
          return if replacement.nil? || (!node.absolute? && ruby_resolves_to?(node, name, replacement))

          register(node, name, replacement) do |corrector|
            corrector.replace(node, node.absolute? ? "::#{replacement}" : replacement)
          end
        end

        def on_pair(node)
          class_name_string(node) do |string, value|
            name = value.delete_prefix("::")
            replacement = deprecated_constants[name]
            next if replacement.nil? || (!value.start_with?("::") && rails_resolves_to?(node, name, replacement))

            register_string(string, name, replacement)
          end
        end

        def on_send(node)
          constantized_string(node) do |string, value|
            name = value.delete_prefix("::")
            replacement = deprecated_constants[name]
            register_string(string, name, replacement) if replacement
          end

          association(node) do |method, association_name|
            check_association(node, method, association_name) unless explicit_class?(node)
          end
        end

      private

        def check_association(node, method, association_name)
          name = inferred_class_name(method, association_name)
          replacement = deprecated_constants[name]
          return if replacement.nil? || rails_resolves_to?(node, name, replacement)

          message = format(ASSOCIATION_MSG, method: method, name: association_name,
                                            deprecated: name, replacement: replacement)
          add_offense(node, message: message) do |corrector|
            anchor = options(node)&.pairs&.last || node.last_argument
            corrector.insert_after(anchor, ", class_name: \"#{replacement}\"")
          end
        end

        def register(node, name, replacement, &block)
          add_offense(node, message: format(MSG, replacement: replacement, deprecated: name), &block)
        end

        def register_string(string, name, replacement)
          register(string, name, replacement) do |corrector|
            corrector.replace(string, "#{string.loc.begin.source}#{replacement}#{string.loc.end.source}")
          end
        end

        def deprecated_constants
          @deprecated_constants ||= cop_config.fetch("Constants", nil).to_h.to_h do |deprecated, replacement|
            [deprecated.to_s.delete_prefix("::"), replacement.to_s.delete_prefix("::")]
          end
        end

        # The name being defined by `class X` or `module X` is not a use of X.
        def class_or_module_name?(node)
          parent = node.parent
          parent&.type?(:class, :module) && parent.identifier.equal?(node)
        end

        def explicit_class?(node)
          options(node)&.pairs&.any? do |pair|
            pair.key.sym_type? && %i[class_name through polymorphic].include?(pair.key.value)
          end
        end

        def options(node)
          node.last_argument if node.last_argument.hash_type?
        end

        def inferred_class_name(method, association_name)
          name = association_name.to_s
          name = name.singularize if COLLECTION_ASSOCIATIONS.include?(method)
          name.camelize
        end
      end
    end
  end
end
