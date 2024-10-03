# frozen_string_literal: true

require "ostruct"

module ScimShady
  module Schema
    class ComplexValue < OpenStruct
      def as_json(...)
        table.as_json(...)
      end
    end

    class ComplexType < ActiveModel::Type::Value
      def initialize(attributes, multi: false)
        @attributes = attributes
        @multi = multi
      end

      def multi?
        @multi
      end

      def cast(value)
        value = JSON.parse(value) if value.is_a?(String)

        if multi?
          cast_multi(value)
        else
          cast_single(value)
        end
      end

      def assert_valid_value(value)
        return value.is_a?(Array) if multi?

        value.is_a?(Hash) && value.keys.eql?(@attributes.keys)
      end

      def cast_multi(value)
        value.map { cast_single(_1) }
      end

      def cast_single(value)
        ComplexValue.new(value)
      end
    end
  end
end
