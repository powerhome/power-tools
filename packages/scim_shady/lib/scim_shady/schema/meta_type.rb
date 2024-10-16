# frozen_string_literal: true

require "ostruct"

module ScimShady
  module Schema
    class MetaValue < OpenStruct
      def as_json(...)
        table.as_json(...)
      end
    end

    class MetaType < ActiveModel::Type::Value
      def cast(value)
        value = JSON.parse(value) if value.is_a?(String)

        MetaValue.new(value).tap(&:freeze)
      end

      def assert_valid_value(value)
        value.is_a?(Hash)
      end
    end
  end
end
