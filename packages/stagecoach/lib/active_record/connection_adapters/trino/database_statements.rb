# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Trino
      module DatabaseStatements
        SLOW_QUERY_NOTIFICATION = "stagecoach.slow_query"

        InternalResult = Struct.new(:column_names, :rows, :column_types, keyword_init: true)

        def execute(sql, name = nil, **_kwargs)
          log(sql, name) { run_trino_query(sql) }
        end

        # Rails 7.1 public path.
        def exec_query(sql, name = "SQL", binds = [], prepare: false, async: false)
          internal_exec_query(sql, name, binds, prepare: prepare, async: async)
        end

        # Rails 7.2+/8.0 canonical path that AR's select_all/select route through.
        # rubocop:disable Lint/UnusedMethodArgument, Metrics/ParameterLists
        def internal_exec_query(sql, name = "SQL", binds = [], prepare: false, async: false, allow_retry: false)
          unless binds.empty?
            raise Stagecoach::Error,
                  "stagecoach: bind variables are not supported; got #{binds.size} bind(s)"
          end

          internal = log(sql, name) { run_trino_query(sql) }
          ActiveRecord::Result.new(internal.column_names, internal.rows, internal.column_types)
        end
        # rubocop:enable Lint/UnusedMethodArgument, Metrics/ParameterLists

        def select_value(arel, name = nil, binds = [])
          result = select_all(arel, name, binds)
          result.rows.first&.first
        end

        def select_values(arel, name = nil, binds = [])
          result = select_all(arel, name, binds)
          result.rows.map(&:first)
        end

      private

        # rubocop:disable Metrics/AbcSize
        def run_trino_query(sql)
          start = monotonic_now
          query = client.query(sql)
          internal = consume_query(query)
          notify_slow_query(sql, monotonic_now - start)
          internal
        rescue ::Trino::Client::TrinoQueryTimeoutError => e
          raise ActiveRecord::StatementTimeout.new(e.message, sql: sql)
        rescue ::Trino::Client::TrinoQueryError => e
          raise ActiveRecord::StatementInvalid.new(e.message, sql: sql)
        rescue ::Trino::Client::TrinoHttpError => e
          raise ActiveRecord::ConnectionFailed, e.message
        ensure
          query&.close if defined?(query) && query
        end
        # rubocop:enable Metrics/AbcSize

        def consume_query(query)
          columns = query.columns || []
          rows = []
          query.each_row_chunk { |chunk| rows.concat(chunk) if chunk }

          column_names = columns.map(&:name)
          column_types = columns.to_h { |c| [c.name, type_map.lookup(c.type)] }
          InternalResult.new(column_names: column_names, rows: rows, column_types: column_types)
        end

        def notify_slow_query(sql, duration)
          return if duration < @slow_query_threshold

          ActiveSupport::Notifications.instrument(
            SLOW_QUERY_NOTIFICATION,
            sql: sql,
            duration: duration
          )
        end

        def monotonic_now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
    end
  end
end
