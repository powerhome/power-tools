# frozen_string_literal: true

require "sequel"
require "date"

module TrinoDateLiteral
  def literal_other(v)
    return "DATE '#{v.iso8601}'" if v.is_a?(Date)

    super
  end
end

Sequel::Database.extend_datasets(TrinoDateLiteral)
