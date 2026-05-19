# frozen_string_literal: true

require "active_record/connection_adapters/column"

module ActiveRecord
  module ConnectionAdapters
    module Trino
      class Column < ActiveRecord::ConnectionAdapters::Column
        def initialize(name:, sql_type:, type:, null: true)
          metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
            sql_type: sql_type,
            type: type.type
          )
          super(name.to_s, nil, metadata, null)
          @cast_type = type
        end

        attr_reader :cast_type
      end
    end
  end
end
