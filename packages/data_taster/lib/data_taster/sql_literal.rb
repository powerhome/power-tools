# frozen_string_literal: true

require "bigdecimal"
require "date"

module DataTaster
  # Necessary to format Ruby values (the non sanitized values) for use as MySQL INSERT literal fragments
  module SqlLiteral
    BINARY_COLUMN_TYPE = /\A(?:tiny|medium|long)?blob|varbinary|binary|bit|geometry/i
    TEXT_COLUMN_TYPE = /\Ajson|(?:var)?char|(?:tiny|medium|long)?text|enum|set/i

    def self.format(client, value, column_type: nil)
      case value
      when String
        format_string_value(client, value, column_type: column_type)
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

    def self.format_string_value(client, value, column_type: nil)
      if is_binary_column?(value, column_type)
        "X'#{value.unpack1('H*')}'"
      else
        "'#{client.escape(encode_as_text(value))}'"
      end
    end
    private_class_method :format_string_value

    def self.is_binary_column?(value, column_type)
      return true if binary_column_type?(column_type)
      return false if text_column_type?(column_type)

      value.encoding == Encoding::ASCII_8BIT && !utf8_text?(value)
    end
    private_class_method :is_binary_column?

    def self.binary_column_type?(column_type)
      return false if column_type.nil?

      column_type.to_s.match?(BINARY_COLUMN_TYPE)
    end
    private_class_method :binary_column_type?

    def self.text_column_type?(column_type)
      return false if column_type.nil?

      column_type.to_s.match?(TEXT_COLUMN_TYPE)
    end
    private_class_method :text_column_type?

    def self.utf8_text?(value)
      value.dup.force_encoding(Encoding::UTF_8).valid_encoding?
    end
    private_class_method :utf8_text?

    def self.encode_as_text(value)
      return value unless value.encoding == Encoding::ASCII_8BIT

      candidate = value.dup.force_encoding(Encoding::UTF_8)
      candidate.valid_encoding? ? candidate : value
    end
    private_class_method :encode_as_text
  end
end
