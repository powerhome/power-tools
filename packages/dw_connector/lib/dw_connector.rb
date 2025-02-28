# frozen_string_literal: true

require_relative "dw_connector/version"
require_relative "dw_connector/data_warehouse_repository"
require_relative "dw_connector/repository_factory"
require_relative "dw_connector/adapters/trino_repository"

# Register default adapters
DWConnector::RepositoryFactory.register(:trino, DWConnector::Adapters::TrinoRepository)

module DWConnector
  class Error < StandardError; end
end
