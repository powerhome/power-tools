# frozen_string_literal: true

require "active_model"

module ActiveRecord
  module ConnectionAdapters
    module Trino
      class TypeMap
        DECIMAL_PATTERN = /\Adecimal\((\d+)\s*(?:,\s*(\d+))?\)\z/i
        TIMESTAMP_TZ_PATTERN = /\Atimestamp(?:\(\d+\))?\s+with\s+time\s+zone\z/i
        COMPOSITE_PATTERN = /\A(?:array|map|row)\(/i

        def self.build
          new
        end

        def initialize
          @cache = {}
        end

        def lookup(trino_type)
          @cache[trino_type] ||= build_type(trino_type.to_s)
        end

      private

        def build_type(sql_type)
          normalized = sql_type.strip.downcase

          string_type(normalized) ||
            integer_type(normalized) ||
            float_type(normalized) ||
            date_time_type(normalized) ||
            decimal_type(normalized) ||
            scalar_type(normalized) ||
            unsupported_type(normalized)
        end

        def string_type(normalized)
          case normalized
          when "varchar", /\Avarchar\(\d+\)\z/,
               "char", /\Achar\(\d+\)\z/,
               "varbinary", /\Avarbinary\(\d+\)\z/,
               "uuid", "ipaddress", "hyperloglog", "qdigest"
            ActiveModel::Type::String.new
          end
        end

        def integer_type(normalized)
          case normalized
          when "tinyint" then ActiveModel::Type::Integer.new(limit: 1)
          when "smallint" then ActiveModel::Type::Integer.new(limit: 2)
          when "integer", "int" then ActiveModel::Type::Integer.new(limit: 4)
          when "bigint" then ActiveModel::Type::Integer.new(limit: 8)
          end
        end

        def float_type(normalized)
          case normalized
          when "real", "double" then ActiveModel::Type::Float.new
          end
        end

        def date_time_type(normalized)
          case normalized
          when "date" then ActiveModel::Type::Date.new
          when "time", /\Atime\(\d+\)\z/ then ActiveModel::Type::Time.new
          when TIMESTAMP_TZ_PATTERN then Stagecoach::Type::TimestampWithZone.new
          when "timestamp", /\Atimestamp\(\d+\)\z/ then ActiveModel::Type::DateTime.new
          end
        end

        def decimal_type(normalized)
          return unless (match = DECIMAL_PATTERN.match(normalized))

          ActiveModel::Type::Decimal.new(
            precision: match[1].to_i,
            scale: (match[2] || 0).to_i
          )
        end

        def scalar_type(normalized)
          case normalized
          when "boolean" then ActiveModel::Type::Boolean.new
          when "json" then Stagecoach::Type::Json.new
          end
        end

        def unsupported_type(normalized)
          Stagecoach::Type::Unsupported.new(normalized)
        end
      end
    end
  end
end
