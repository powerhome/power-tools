# frozen_string_literal: true

require "active_model"
require "time"

module Stagecoach
  module Type
    class TimestampWithZone < ActiveModel::Type::Value
      def type
        :datetime
      end

      def cast(value)
        return value if value.nil? || value.is_a?(::Time) || value.is_a?(::DateTime)
        return value unless value.is_a?(::String)

        ::Time.parse(value)
      rescue ::ArgumentError
        value
      end
    end
  end
end
