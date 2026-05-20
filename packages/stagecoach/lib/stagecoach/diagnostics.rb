# frozen_string_literal: true

require "benchmark"

module Stagecoach
  # Diagnostic helpers for stagecoach-backed models. Useful when
  # investigating why a Trino-backed query is slow.
  module Diagnostics
  module_function

    # Profile a Trino-backed AR model's first-query latency. Resets
    # the column cache to force a schema re-fetch, times it, then runs
    # a sample SELECT and pulls the per-query breakdown from Trino's
    # own response.
    #
    # Returns a Hash with:
    #   :schema_time      Float seconds spent on information_schema.columns
    #   :query_time       Float seconds spent on the sample SELECT (Ruby-side)
    #   :query_id         Trino query_id (cross-reference in the Trino UI)
    #   :info_uri         URL to the query's stats page in the Trino UI
    #   :queued_time_ms   Trino-side: time the query spent queued
    #   :elapsed_time_ms  Trino-side: total wall clock (queued + execution)
    #   :cpu_time_ms      Trino-side: CPU time spent on the query
    #   :wall_time_ms     Trino-side: wall-clock execution time (planning + exec)
    #   :state            "FINISHED" / "FAILED" / etc.
    #
    # Note: the Trino 351 StatementStats model does not expose
    # planning_time as a discrete field — it is folded into wall_time.
    # If you need the planning slice specifically, subtract wall_time
    # from elapsed_time as a rough approximation.
    def profile(model_class)
      connection = model_class.connection
      model_class.reset_column_information
      schema_time = ::Benchmark.realtime { model_class.columns }

      # Issue the sample SELECT through the adapter directly so it is the
      # last query touching the connection — AR's higher-level paths can
      # fire follow-up bookkeeping queries (SHOW TABLES, etc.) that would
      # otherwise overwrite last_query_* before we read them.
      table = connection.quote_table_name(model_class.table_name)
      sql = "SELECT * FROM #{table} LIMIT 1"
      query_time = ::Benchmark.realtime { connection.exec_query(sql) }

      build_result(connection, schema_time, query_time)
    end

    def build_result(connection, schema_time, query_time)
      stats = connection.last_query_stats || {}
      {
        schema_time: schema_time,
        query_time: query_time,
        query_id: connection.last_query_id,
        info_uri: connection.last_query_info_uri,
        queued_time_ms: stats[:queued_time_millis],
        elapsed_time_ms: stats[:elapsed_time_millis],
        cpu_time_ms: stats[:cpu_time_millis],
        wall_time_ms: stats[:wall_time_millis],
        state: stats[:state],
      }
    end
  end
end
