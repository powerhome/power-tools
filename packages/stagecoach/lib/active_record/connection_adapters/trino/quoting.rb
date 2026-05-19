# frozen_string_literal: true

require "bigdecimal"
require "date"
require "time"

module ActiveRecord
  module ConnectionAdapters
    module Trino
      module Quoting
        QUOTED_TRUE = "true"
        QUOTED_FALSE = "false"
        QUOTED_NULL = "NULL"

        TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%3N"
        DATE_FORMAT = "%Y-%m-%d"

        NUL_BYTE = /\x00/

        # rubocop:disable Metrics/CyclomaticComplexity, Lint/DuplicateBranch
        def quote(value)
          case value
          when nil then QUOTED_NULL
          when true then QUOTED_TRUE
          when false then QUOTED_FALSE
          when BigDecimal then value.to_s("F")
          when Numeric then value.to_s
          when ::Date then "DATE '#{value.strftime(DATE_FORMAT)}'"
          when ::Time, ::DateTime then quote_time(value)
          when Symbol, String then quote_string_literal(value.to_s)
          else quote_string_literal(value.to_s)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Lint/DuplicateBranch

        def quote_string(string)
          str = string.to_s
          if str.match?(NUL_BYTE)
            raise Stagecoach::Error,
                  "stagecoach: NUL byte detected in literal; refusing to quote"
          end
          str.gsub("'", "''")
        end

        def quote_column_name(name)
          %("#{name.to_s.gsub('"', '""')}")
        end

        def quote_table_name(name)
          name.to_s.split(".").map { |part| quote_column_name(part) }.join(".")
        end

        def quoted_true
          QUOTED_TRUE
        end

        def quoted_false
          QUOTED_FALSE
        end

        def quoted_date(value)
          value.strftime(DATE_FORMAT)
        end

      private

        def quote_string_literal(string)
          "'#{quote_string(string)}'"
        end

        def quote_time(value)
          time = value.respond_to?(:utc) ? value.utc : value
          "TIMESTAMP '#{time.strftime(TIMESTAMP_FORMAT)}'"
        end
      end
    end
  end
end
