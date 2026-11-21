# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # Works out, from a node's enclosing classes and modules, which full
      # names Ruby or Rails would try, in order, for a relative constant name.
      module ConstantResolution
        # A relative constant is searched for in each enclosing class or
        # module, innermost first, then at the top level. `module A; class B`
        # searches `A::B` then `A`, while the compact `class A::B` searches
        # only `A::B`.
        def ruby_candidates(node, name)
          lexical_scopes(node).map { |scope| "#{scope}::#{name}" } << name
        end

        # Rails resolves a relative class name (an association's inferred or
        # `class_name:` class) by trying each of the model's own namespaces,
        # longest first (`A::B::Name`, then `A::Name`), then the top level.
        # Outside a class body (a concern's `included` block, say) the model is
        # not known, so the enclosing module's namespaces stand in for it.
        def rails_candidates(node, name)
          parts = lexical_scopes(node).first.to_s.split("::")
          parts.size.downto(1).map { |size| "#{parts.first(size).join('::')}::#{name}" } << name
        end

        # Whether the node sits in a class body, so the model Rails resolves
        # names from is the enclosing class rather than whatever includes it.
        def model_known?(node)
          node.each_ancestor(:class, :module).first&.class_type? || false
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
