# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      class Inheritance < RuboCop::Cop::Cop
        PROTECTED_GLOBAL_CONSTANTS = %w[
          ApplicationController
          ApplicationRecord
          ApiController
        ].freeze

        MSG = "Do not directly inherit from a global %<class>s. " \
              "Instead, inherit from your component's modularized " \
              "%<class>s, such as MyComponent::%<class>s."

        def on_class(node)
          inheritance_constant = node.node_parts[1]
          inheritance_class = inheritance_constant&.source
          return unless PROTECTED_GLOBAL_CONSTANTS.include?(inheritance_class)

          add_offense(inheritance_constant,
                      message: format(MSG, class: inheritance_class))
        end
      end
    end
  end
end
