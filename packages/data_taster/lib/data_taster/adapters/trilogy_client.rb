# frozen_string_literal: true

module DataTaster
  # Exposes a Trilogy connection through the Mysql2::Client interface DataTaster relies on
  class TrilogyClient
    # Yields rows as hashes, like Mysql2::Result. Trilogy does not report column types.
    class Result
      include Enumerable

      def initialize(result)
        @result = result
      end

      def fields
        @result.fields
      end

      def field_types
        []
      end

      def each(&block)
        @result.each_hash(&block)
      end
    end

    def self.wrap(client)
      defined?(::Trilogy) && client.is_a?(::Trilogy) ? new(client) : client
    end

    def initialize(client)
      @client = client
    end

    def query(sql)
      Result.new(@client.query(sql))
    end

    def query_options
      { database: @client.connection_options[:database] }
    end

    def escape(value)
      @client.escape(value)
    end
  end
end
