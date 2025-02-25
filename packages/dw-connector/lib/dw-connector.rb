# frozen_string_literal: true

require_relative "dw-connector/version"
require_relative "dw-connector/data_warehouse_repository"
require_relative "dw-connector/repository_factory"
require_relative "dw-connector/adapters/trino_repository"

module DWConnector
  class Error < StandardError; end
end
