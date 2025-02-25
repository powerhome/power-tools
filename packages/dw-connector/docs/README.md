# DW Connector

A flexible Ruby data warehouse connector library that provides a standardized interface for querying different data warehouse engines. Currently supports Trino with an extensible architecture for adding other engines.

## Features

- Unified interface for querying data warehouses
- Built-in support for Trino
- Extensible adapter system for adding new data warehouse engines
- Flexible data transformation options
- Environment-based configuration with overrides
- Automatic query pagination handling
- Error handling and retries

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dw-connector'
```

Or install it directly:

```bash
gem install dw-connector
```

## Basic Usage

```ruby
require 'dw-connector'

# Create a repository using defaults (reads from environment variables)
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales"
)

# Query with conditions
results = repository.query("status = 'completed'")

# Execute custom SQL
results = repository.execute("SELECT date, SUM(amount) FROM sales GROUP BY date")
```

## Configuration

### Data Warehouse Configuration

You can configure the connector through environment variables or by passing a config hash:

```ruby
# Using environment variables
ENV['TRINO_SERVER'] = 'http://trino.company.com:8080'
ENV['TRINO_USER'] = 'analyst'
ENV['TRINO_CATALOG'] = 'prod'
ENV['TRINO_SCHEMA'] = 'sales'

# Or passing configuration directly
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales",
  config: {
    server: "http://trino.company.com:8080",
    user: "analyst",
    catalog: "prod",
    schema: "sales"
  }
)
```

### Data Transformation Options

The connector provides flexible options for transforming query results:

```ruby
# Default behavior - string keys, no transformations
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales"
)
# Result: { "USER_ID" => 1, "TOTAL_AMOUNT" => "100.50" }

# Using symbol keys
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales",
  config: {
    transform_options: { keys: :symbol }
  }
)
# Result: { USER_ID: 1, TOTAL_AMOUNT: "100.50" }

# Transform keys to lowercase
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales",
  config: {
    transform_options: {
      transform_keys: ->(key) { key.downcase }
    }
  }
)
# Result: { "user_id" => 1, "total_amount" => "100.50" }

# Clean string values
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales",
  config: {
    transform_options: {
      transform_values: ->(value) { value.is_a?(String) ? value.strip : value }
    }
  }
)
# Result: { "USER_ID" => 1, "TOTAL_AMOUNT" => "100.50" }

# Combine multiple transformations
repository = DWConnector::RepositoryFactory.create(
  type: :trino,
  table_name: "sales",
  config: {
    transform_options: {
      keys: :symbol,
      transform_keys: ->(key) { key.downcase },
      transform_values: ->(value) { value.is_a?(String) ? value.strip : value }
    }
  }
)
# Result: { user_id: 1, total_amount: "100.50" }
```

## Adding a New Adapter

To add support for a new data warehouse engine, create a new adapter that implements the `DataWarehouseRepository` interface:

```ruby
module DWConnector
  module Adapters
    class BigQueryRepository
      include DataWarehouseRepository

      def initialize(table_name, conditions = nil, config = {})
        @table_name = table_name
        @conditions = conditions
        @config = config
        # Initialize connection details
      end

      def query(sql_query = nil)
        sql_query ||= build_query
        process_query_response(execute(sql_query))
      end

      def execute(sql_query)
        # Execute query and return results
        # Results will automatically be transformed according to config
      end

      private

      def process_query_response(response)
        # Transform the raw response into the expected format:
        # { result_data: [[1, "test"]], result_columns: [{ "name" => "id" }, { "name" => "name" }] }
      end
    end
  end
end
```

Then register it in the factory:

```ruby
# lib/dw-connector/repository_factory.rb
def repository_for(type)
  case type
  when :trino
    Adapters::TrinoRepository
  when :bigquery
    Adapters::BigQueryRepository
  else
    raise ArgumentError, "Unsupported repository type: #{type}"
  end
end
```

## Development

1. Clone the repository
2. Install dependencies: `bundle install`
3. Run the test suite: `bundle exec rspec`
4. Run the linter: `bundle exec rubocop`

### Testing Changes Locally

```ruby
# In your application's Gemfile
gem "dw-connector", path: "path/to/packages/dw-connector"
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.txt file for details.