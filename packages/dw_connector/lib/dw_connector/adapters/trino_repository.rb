# frozen_string_literal: true

require "rest-client"
require "json"
require "base64"

module DWConnector
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

      def query(sql_query = nil)
        sql_query ||= build_query
        execute(sql_query)
      end

      def execute(sql_query)
        response_data = process_response(send_query(sql_query))
        transform_response(response_data[:result_data], response_data[:result_columns])
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

      def build_query
        query = "SELECT * FROM #{table_name}"
        query += " WHERE #{conditions}" if conditions
        query
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

        { result_data:, result_columns: }
      end

      def send_query(sql)
        JSON.parse(RestClient.post("#{server}/v1/statement", sql, headers).body)
      rescue RestClient::ExceptionWithResponse => e
        raise DWConnector::Error, "Query failed: #{e.response&.body}"
      end

      def fetch_next(uri)
        JSON.parse(RestClient.get(uri, headers).body)
      rescue RestClient::ExceptionWithResponse => e
        raise DWConnector::Error, "Failed to fetch next page: #{e.response&.body}"
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
