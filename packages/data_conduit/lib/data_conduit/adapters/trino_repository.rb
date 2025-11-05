# frozen_string_literal: true

require "rest-client"
require "json"
require "base64"
require "sequel"

module DataConduit
  module Adapters
    class TrinoRepository
      include DataWarehouseRepository

      attr_reader :server, :user, :password, :catalog, :schema, :table_name, :conditions, :config

      def initialize(table_name, conditions = nil, config = {})
        @table_name = table_name
        @conditions = conditions
        @config = default_config.merge(config)
        @server = @config[:server]
        @user = @config[:user]
        @password = @config[:password]
        @catalog = @config[:catalog]
        @schema = @config[:schema]

        validate_config!
      end

      def self.tables(config)
        repo = new(nil, nil, config)
        response_data = repo.send(:response_to, "SHOW tables")
        response_data[:result_data]&.flatten&.sort
      end

      def query(sql_query = nil)
        sql_query ||= build_query
        execute(sql_query)
      end

      def execute(sql_query)
        response_data = response_to(sql_query)
        transform_response(response_data[:result_data], response_data[:result_columns])
      end

      def last_updated
        response_data = response_to("SELECT made_current_at FROM \"#{table_name}$history\" " \
                                    "ORDER BY made_current_at DESC LIMIT 1")
        datetime_string = response_data[:result_data]&.flatten&.first
        datetime_string.nil? ? nil : DateTime.parse(datetime_string)
      end

    private

      def default_config
        {
          server: ENV.fetch("TRINO_SERVER", "http://localhost:8090"),
          user: ENV.fetch("TRINO_USER", "trino"),
          password: ENV.fetch("TRINO_PASSWORD", nil),
          catalog: ENV.fetch("TRINO_CATALOG", "default"),
          schema: ENV.fetch("TRINO_SCHEMA", "default"),
        }
      end

      def validate_config!
        %i[server user catalog schema].each do |key|
          value = instance_variable_get(:"@#{key}")
          raise ArgumentError, "#{key} cannot be nil or empty" if value.nil? || value.empty?
        end
      end

      # Build a SQL query using Sequel as a sanitizer and SQL builder.
      # We use Sequel.mock so that no actual connection is made.
      def build_query
        db = Sequel.mock
        dataset = db.from(Sequel.identifier(table_name)).select_all

        if conditions
          unless conditions.is_a?(Hash)
            raise ArgumentError, "Conditions must be provided as a Hash for safe query building"
          end

          converted_conditions = convert_string_keys(conditions)
          dataset = dataset.where(converted_conditions)
        end

        dataset.sql
      end

      def convert_string_keys(conditions_hash)
        conditions_hash.transform_keys do |key|
          key.is_a?(String) || key.is_a?(Symbol) ? Sequel[key.to_sym] : key
        end
      end

      def response_to(sql)
        process_response(send_query(sql))
      end

      def process_response(initial_response)
        result_data = []
        result_columns = nil
        response_data = initial_response

        while response_data
          result_data.concat(response_data["data"]) if response_data["data"]
          result_columns ||= response_data["columns"]
          next_uri = response_data["nextUri"]
          response_data = next_uri ? fetch_next(next_uri) : nil
        end

        { result_data: result_data, result_columns: result_columns }
      end

      def send_query(sql)
        base_url = server.end_with?("/") ? server.chop : server
        endpoint = "#{base_url}/v1/statement"
        JSON.parse(RestClient.post(endpoint, sql, headers).body)
      rescue JSON::ParserError => e
        raise DataConduit::Error, "Failed to parse JSON response: #{e.message}"
      rescue RestClient::ExceptionWithResponse => e
        raise DataConduit::Error, "Query failed: #{e.response&.body}"
      end

      def fetch_next(uri)
        JSON.parse(RestClient.get(uri, headers).body)
      rescue RestClient::ExceptionWithResponse => e
        raise DataConduit::Error, "Failed to fetch next page: #{e.response&.body}"
      end

      def headers
        headers = {
          "X-Trino-Catalog" => catalog,
          "X-Trino-Schema" => schema,
        }

        # Add basic auth if password is provided, otherwise use X-Trino-User header
        if password && !password.empty?
          headers["Authorization"] = "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
        else
          headers["X-Trino-User"] = user
        end

        headers
      end
    end
  end
end
