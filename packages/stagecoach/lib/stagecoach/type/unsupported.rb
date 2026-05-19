# frozen_string_literal: true

require "active_model"

module Stagecoach
  module Type
    class Unsupported < ActiveModel::Type::Value
      def initialize(trino_type = nil)
        super()
        @trino_type = trino_type
      end

      def type
        :unsupported
      end

      def cast(_value)
        raise Stagecoach::UnsupportedTypeError,
              "stagecoach: cannot cast Trino type #{@trino_type.inspect}; " \
              "select scalar columns explicitly or extract values via Trino SQL"
      end
    end
  end
end
