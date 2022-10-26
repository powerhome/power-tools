# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      class GemRequirement < RuboCop::Cop::Cop
        MSG = "Component Gemfile dependencies must specify " \
              "'require: nil'."

        def investigate(processed_source)
          return if processed_source.blank?

          gem_block = component_gem_block(processed_source.ast)&.first
          return unless gem_block

          process_component_declarations(gem_block)
        end

      private

        def process_component_declarations(gem_block)
          if gem_block.send_type?
            add_gem_offenses(gem_block)
          else
            gem_listings(gem_block).each do |gem_node|
              add_gem_offenses(gem_node)
            end
          end
        end

        def add_gem_offenses(gem_node)
          component_options = gem_options(gem_node).first
          return if component_options && not_required?(component_options)

          add_offense(gem_node, message: MSG)
        end

        def_node_matcher :component_gem_block, <<~PATTERN
          (:begin ...
            (:block
              (:send nil? :path (:str ".."))
              (:args)
              $...
            )
          )
        PATTERN

        def_node_matcher :gem_options, "(:send nil? :gem _ $...)"
        def_node_matcher :gem_listings, "(:begin $...)"

        def_node_matcher :not_required?, <<~PATTERN
          (:hash
            (:pair
              (:sym :require)
              (${nil false})
            )
          )
        PATTERN
      end
    end
  end
end
