# frozen_string_literal: true

require_relative "dw_conduit/version"
require_relative "dw_conduit/data_warehouse_repository"
require_relative "dw_conduit/repository_factory"
require_relative "dw_conduit/adapters/trino_repository"

# Register default adapters
DWConduit::RepositoryFactory.register(:trino, DWConduit::Adapters::TrinoRepository)

module DWConduit
  class Error < StandardError; end
end
