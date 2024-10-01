# frozen_string_literal: true

module ScimShady
  module Schema
    class Attribute
      attr_reader :name, :type, :options

      def initialize(opts)
        @options = opts
        @name = opts["name"].to_sym
        @type = model_type_for(opts["type"])
      end

      def mutability
        options["mutability"]
      end

      def read?
        !mutability.eql?("writeOnly")
      end

      def write?
        !immutable? && !mutability.eql?("readOnly")
      end

      def immutable?
        mutability.eql?("immutable")
      end

      def multi?
        options["multiValued"]
      end

      private

      def sub_attributes
        Attributes.new(options["subAttributes"])
      end

      def model_type_for(type)
        type.eql?("complex") ? ComplexType.new(sub_attributes, multi: multi?) : type.to_sym
      end
    end
  end
end
