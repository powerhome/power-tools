# frozen_string_literal: true

require "sequel"
require "date"
require "active_support/time"

module TrinoDateLiteral
  ISO_TS = "%F %T.%6N" # => "YYYY-MM-DD hh:mm:ss.ffffff"

  def literal_date(v)
    "DATE '#{v.iso8601}'"
  end

  def literal_datetime(v) = timestamp_literal(v)
  def literal_time(v)      = timestamp_literal(v)

private

  def timestamp_literal(v)
    "TIMESTAMP '#{v.strftime(ISO_TS)}'"
  end
end

Sequel::Dataset.prepend(TrinoDateLiteral)
