# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Works out, from a node's enclosing classes and modules, whether Ruby or
      # Rails would resolve a relative constant name to a given full name.
      module ConstantResolution
        # A relative constant is searched for in each enclosing class or
        # module, innermost first. `module A; class B` searches `A::B` then
        # `A`, while the compact `class A::B` searches only `A::B`.
        def ruby_resolves_to?(node, name, full_name)
          lexical_scopes(node).any? { |scope| "#{scope}::#{name}" == full_name }
        end

        # Rails resolves a relative class name (an association's inferred or
        # `class_name:` class) by trying each of the model's own namespaces,
        # longest first (`A::B::Name`, then `A::Name`), then the top level.
        def rails_resolves_to?(node, name, full_name)
          model = lexical_scopes(node).first
          return false unless model

          parts = model.split("::")
          parts.size.downto(1).any? { |size| "#{parts.first(size).join('::')}::#{name}" == full_name }
        end

        # Full names of the enclosing classes and modules, innermost first.
        def lexical_scopes(node)
          names = node.each_ancestor(:class, :module).map { |scope| scope.identifier.source }
          names.each_index.map do |index|
            chain = []
            names[index..].each do |name|
              chain.unshift(name.delete_prefix("::"))
              break if name.start_with?("::")
            end
            chain.join("::")
          end
        end
      end
    end
  end
end
