# frozen_string_literal: true

require "active_record"
require "active_record/connection_adapters/abstract_adapter"
require "trino-client"

require "stagecoach"

require_relative "trino/quoting"
require_relative "trino/type_map"
require_relative "trino/column"
require_relative "trino/database_statements"
require_relative "trino/schema_statements"
require_relative "trino/read_only"
require_relative "trino/safety_belts"

module ActiveRecord
  module ConnectionAdapters
    class TrinoAdapter < AbstractAdapter
      ADAPTER_NAME = "Trino"

      include Trino::Quoting
      include Trino::DatabaseStatements
      include Trino::SchemaStatements
      include Trino::ReadOnly

      def initialize(...)
        super
        @client_options = Stagecoach::Config.client_options(@config)
        @slow_query_threshold = Stagecoach::Config.slow_query_threshold(@config)
        @client = build_client
        install_safety_belts!
      end

      def adapter_name
        ADAPTER_NAME
      end

      def active?
        !@client.nil?
      end

      def reconnect!
        disconnect!
        @client = build_client
      end

      def disconnect!
        @client = nil
      end

      def supports_transactions?
        false
      end

      def supports_savepoints?
        false
      end

      def supports_lazy_transactions?
        false
      end

      def supports_advisory_locks?
        false
      end

      def supports_explain?
        true
      end

      def supports_migrations?
        false
      end

      def supports_ddl_transactions?
        false
      end

      def supports_views?
        false
      end

      # ActiveRecord's adapter API expects this method name without a question mark.
      def prepared_statements # rubocop:disable Naming/PredicateMethod
        false
      end

      def requires_reloading?
        false
      end

      def native_database_types
        {}
      end

      def lookup_cast_type(sql_type)
        type_map.lookup(sql_type)
      end

      def lookup_cast_type_from_column(column)
        column.cast_type
      end

      attr_reader :client, :last_query_id, :last_query_info_uri, :last_query_stats

    private

      def build_client
        ::Trino::Client.new(@client_options)
      end

      def type_map
        @type_map ||= Trino::TypeMap.build
      end

      def install_safety_belts!
        return unless defined?(::ActiveRecord::Relation)

        return if ::ActiveRecord::Relation.include?(RelationSafetyBelts)

        ::ActiveRecord::Relation.prepend(RelationSafetyBelts)
      end

      # The safety belts override AR::Relation batch methods only when the relation's
      # connection is a TrinoAdapter, so they don't leak into other databases used in
      # the same process.
      module RelationSafetyBelts
        Trino::SafetyBelts::BATCH_METHODS.each do |method|
          define_method(method) do |*args, **kwargs, &block|
            if connection.is_a?(::ActiveRecord::ConnectionAdapters::TrinoAdapter)
              raise Stagecoach::Error,
                    "stagecoach: #{method} is not supported on Trino-backed models. " \
                    "Use explicit LIMIT/OFFSET pagination or pluck aggregates instead."
            else
              super(*args, **kwargs, &block)
            end
          end
        end
      end
    end
  end
end
