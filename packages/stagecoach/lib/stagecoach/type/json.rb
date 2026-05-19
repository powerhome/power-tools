# frozen_string_literal: true

require "active_model"
require "json"

module Stagecoach
  module Type
    class Json < ActiveModel::Type::Value
      def type
        :json
      end

      def cast(value)
        return value if value.nil? || value.is_a?(::Hash) || value.is_a?(::Array)
        return value unless value.is_a?(::String)

        ::JSON.parse(value)
      rescue ::JSON::ParserError
        value
      end
    end
  end
end
