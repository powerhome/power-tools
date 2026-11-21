# frozen_string_literal: true

require "active_support/inflector"

module RuboCop
  module Cop
    module Cobra
      # Reads an ActiveRecord association call (`belongs_to :territory, ...`)
      # for the class Rails infers from its name.
      module AssociationClass
        COLLECTION_ASSOCIATIONS = %i[has_many has_and_belongs_to_many].freeze
        NON_MODEL_CLASS = /(?:Serializer|Resource)\z/
        MODEL_PARENT = /(?:Record|ActiveRecord::Base)\z/

        # Options that name the class or stop Rails inferring it from the name.
        def explicit_class?(node)
          options(node)&.pairs&.any? do |pair|
            pair.key.sym_type? && %i[class_name through polymorphic].include?(pair.key.value)
          end
        end

        # Serializer and API resource DSLs (ActiveModel::Serializers,
        # jsonapi-serializer, Graphiti) borrow the association method names but
        # do not resolve a class from them or take `class_name:`. A class counts
        # when its parent ends in Serializer or Resource, or when its own name
        # does and its parent is not a model base class, so a model such as
        # `AdditionalResource < ApplicationRecord` is still checked.
        def non_model_class?(node)
          klass = node.each_ancestor(:class).first
          return false unless klass

          parent = klass.parent_class&.source
          return true if parent&.match?(NON_MODEL_CLASS)
          return false if parent&.match?(MODEL_PARENT)

          klass.identifier.source.match?(NON_MODEL_CLASS)
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
