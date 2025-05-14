# frozen_string_literal: true

require_relative "data_conduit/version"
require_relative "data_conduit/data_warehouse_repository"
require_relative "data_conduit/repository_factory"
require_relative "data_conduit/adapters/trino_repository"
require_relative "data_conduit/infrastructure/sequel/trino_date_literal"

# Register default adapters
DataConduit::RepositoryFactory.register(:trino, DataConduit::Adapters::TrinoRepository)

module DataConduit
  class Error < StandardError; end
end
