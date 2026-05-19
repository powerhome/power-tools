# frozen_string_literal: true

require "active_record"
require "active_support"
require "active_support/notifications"
require "trino-client"

require_relative "stagecoach/version"
require_relative "stagecoach/errors"
require_relative "stagecoach/config"
require_relative "stagecoach/type/json"
require_relative "stagecoach/type/timestamp_with_zone"
require_relative "stagecoach/type/unsupported"

ActiveRecord::ConnectionAdapters.register(
  "trino",
  "ActiveRecord::ConnectionAdapters::TrinoAdapter",
  "active_record/connection_adapters/trino_adapter"
)

module Stagecoach
  def self.reset_schema_cache!(model_class)
    model_class.reset_column_information
    model_class.connection.schema_cache.clear! if model_class.connection.respond_to?(:schema_cache)
  end
end
