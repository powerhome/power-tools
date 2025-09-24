# Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Adding a New Adapter

To add support for a new data warehouse engine, create a new adapter that implements the `DataWarehouseRepository` interface:

```ruby
module DataConduit
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
# lib/data_conduit/repository_factory.rb
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
