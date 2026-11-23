# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Requires every Rails engine to call `isolate_namespace` with the
      # module the engine is defined in.
      #
      # Without it, the engine's routes, helpers and models leak into the host
      # application: its route helpers and `url_for` resolve against the app's
      # routes, every engine helper is mixed into every controller, and its
      # generators write into the global namespace.
      #
      # An engine defined without a namespace (a top-level `class Engine`) is
      # ignored, since there is no module to isolate it in.
      #
      # There is no autocorrect. Adding `isolate_namespace` also gives the
      # engine's models a table name prefix (`my_component_`) unless the
      # module already defines `table_name_prefix`, and renames its route
      # helpers, so each engine needs a person to check its tables and routes.
      #
      # @example
      #   # bad
      #   module MyComponent
      #     class Engine < ::Rails::Engine
      #     end
      #   end
      #
      #   # bad
      #   module MyComponent
      #     class Engine < ::Rails::Engine
      #       isolate_namespace OtherComponent
      #     end
      #   end
      #
      #   # good
      #   module MyComponent
      #     class Engine < ::Rails::Engine
      #       isolate_namespace MyComponent
      #     end
      #   end
      #
      class EngineIsolateNamespace < RuboCop::Cop::Base
        MISSING_MSG = "Call `isolate_namespace %<namespace>s` in the engine."
        MISMATCH_MSG = "Isolate the engine in its own namespace, `%<namespace>s`."

        # @!method engine_class?(node)
        def_node_matcher :engine_class?, <<~PATTERN
          (class _ (const (const {nil? cbase} :Rails) :Engine) _)
        PATTERN

        # @!method isolate_namespace(node)
        def_node_matcher :isolate_namespace, <<~PATTERN
          (send {nil? self} :isolate_namespace $_)
        PATTERN

        def on_class(node)
          return unless engine_class?(node)

          namespace = enclosing_namespace(node)
          return if namespace.nil?

          call = body_statements(node).find { |statement| isolate_namespace(statement) }
          return add_offense(header(node), message: format(MISSING_MSG, namespace: namespace)) if call.nil?

          argument = isolate_namespace(call)
          return if argument.source.delete_prefix("::") == namespace

          add_offense(argument, message: format(MISMATCH_MSG, namespace: namespace))
        end

      private

        def enclosing_namespace(node)
          names = node.each_ancestor(:class, :module).map { |scope| scope.identifier.source }.reverse
          names << node.identifier.namespace&.source
          names.compact.map { |name| name.delete_prefix("::") }.join("::").then { |name| name unless name.empty? }
        end

        def body_statements(node)
          body = node.body
          return [] if body.nil?

          body.begin_type? ? body.children : [body]
        end

        def header(node)
          node.loc.keyword.join(node.parent_class.source_range)
        end
      end
    end
  end
end
