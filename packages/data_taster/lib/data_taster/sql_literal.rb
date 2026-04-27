# frozen_string_literal: true

require "bigdecimal"
require "date"

module DataTaster
  # Necessary to format Ruby values for use as MySQL INSERT literal fragments
  module SqlLiteral
    def self.format(client, value)
      case value
      when String
        format_string_value(client, value)
      when nil, true, false, Integer, Float, BigDecimal
        format_scalar(value)
      when Time, DateTime, Date
        format_temporal(client, value)
      else
        "'#{client.escape(value.to_s)}'"
      end
    end

    def self.format_temporal(client, value)
      case value
      when Time
        format_escaped_time(client, value, "%Y-%m-%d %H:%M:%S")
      when DateTime
        format_escaped_time(client, value.to_time, "%Y-%m-%d %H:%M:%S")
      when Date
        format_escaped_date(client, value)
      end
    end
    private_class_method :format_temporal

    def self.format_scalar(value)
      return "NULL" if value.nil?
      return "TRUE" if value == true
      return "FALSE" if value == false
      return value.to_s if value.is_a?(Integer)
      return value.finite? ? value.to_s : "NULL" if value.is_a?(Float)

      value.to_s("F")
    end
    private_class_method :format_scalar

    def self.format_escaped_time(client, time, strftime_format)
      "'#{client.escape(time.strftime(strftime_format))}'"
    end
    private_class_method :format_escaped_time

    def self.format_escaped_date(client, value)
      "'#{client.escape(value.strftime('%Y-%m-%d'))}'"
    end
    private_class_method :format_escaped_date

    def self.format_string_value(client, value)
      if value.encoding == Encoding::ASCII_8BIT
        "X'#{value.unpack1('H*')}'"
      else
        "'#{client.escape(value)}'"
      end
    end
    private_class_method :format_string_value
  end
end
