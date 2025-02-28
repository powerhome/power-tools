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
gem 'dw_connector'
```

Or install it directly:

```bash
gem install dw_connector
```

## Basic Usage

```ruby
require 'dw_connector'

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

## Development

1. Clone the repository
2. Install dependencies: `bundle install`
3. Run the test suite: `bundle exec rspec`
4. Run the linter: `bundle exec rubocop`

### Testing Changes Locally

```ruby
# In your application's Gemfile
gem "dw_connector", path: "path/to/packages/dw_connector"
```

## License

This project is licensed under the MIT License - see the LICENSE.txt file for details.