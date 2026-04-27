# frozen_string_literal: true

require "bigdecimal"
require "date"

module DataTaster
  # Necessary to format Ruby values for use as MySQL INSERT literal fragments
  module SqlLiteral
    module_function

    def format(client, value)
      case value
      when nil
        "NULL"
      when true
        "TRUE"
      when false
        "FALSE"
      when Integer
        value.to_s
      when Float
        value.finite? ? value.to_s : "NULL"
      when BigDecimal
        value.to_s("F")
      when Time
        "'#{client.escape(value.strftime('%Y-%m-%d %H:%M:%S'))}'"
      when DateTime
        "'#{client.escape(value.to_time.strftime('%Y-%m-%d %H:%M:%S'))}'"
      when Date
        "'#{client.escape(value.strftime('%Y-%m-%d'))}'"
      when Symbol
        "'#{client.escape(value.to_s)}'"
      when String
        if value.encoding == Encoding::ASCII_8BIT
          "X'#{value.unpack1('H*')}'"
        else
          "'#{client.escape(value)}'"
        end
      else
        "'#{client.escape(value.to_s)}'"
      end
    end
  end
end
