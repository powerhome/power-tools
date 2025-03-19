# frozen_string_literal: true

module DataConduit
  module DataWarehouseRepository
    DEFAULT_TRANSFORM_OPTIONS = {
      keys: :string,        # :string or :symbol
      transform_keys: nil,  # optional proc for key transformation
      transform_values: nil, # optional proc for value transformation
    }.freeze

    def self.included(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def initialize(_table_name, _conditions = nil, _config = {})
        validate_table_name(table_name)
        raise NotImplementedError, "You must implement the initialize method"
      end

      def query(_sql_query = nil)
        raise NotImplementedError, "You must implement the query method"
      end

      def execute(_sql_query)
        raise NotImplementedError, "You must implement the execute method"
      end

    protected

      def validate_table_name(table_name)
        raise ArgumentError, "Table name cannot be blank" if table_name.nil? || table_name.empty?

        return if table_name.to_s.match?(/^[a-zA-Z0-9_\.]+$/)

        raise ArgumentError, "Invalid table name format. Table name must contain only letters, " \
                             "numbers, underscores, and periods."
      end

      def transform_response(result_data, result_columns)
        return [] if result_data.nil? || result_data.empty?

        columns = extract_column_names(result_columns)
        result_data.map do |row|
          transform_row(columns.zip(row).to_h)
        end
      end

      def transform_row(row)
        row = row.transform_keys { |key| transform_key(key) }
        row = row.transform_values(&transform_options[:transform_values]) if transform_options[:transform_values]
        row
      end

      def transform_key(key)
        key = transform_options[:transform_keys]&.call(key) || key
        transform_options[:keys] == :symbol ? key.to_sym : key.to_s
      end

      def transform_options
        @transform_options ||= DEFAULT_TRANSFORM_OPTIONS.merge(
          config.fetch(:transform_options, {})
        )
      end

      # Can be overridden by adapters if they have different column name structures
      def extract_column_names(columns)
        columns.map { |col| col["name"] }
      end
    end
  end
end
