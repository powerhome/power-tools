# frozen_string_literal: true

require "sequel"
require "date"
require "active_support"
require "active_support/time"

module TrinoDateLiteral
  ISO_TS = "%F %T.%6N" # => "YYYY-MM-DD hh:mm:ss.ffffff"

  def literal_date(value)
    "DATE '#{value.iso8601}'"
  end

  def literal_datetime(value) = timestamp_literal(value)
  def literal_time(value) = timestamp_literal(value)

private

  def timestamp_literal(value)
    "TIMESTAMP '#{value.strftime(ISO_TS)}'"
  end
end

Sequel::Dataset.prepend(TrinoDateLiteral)
