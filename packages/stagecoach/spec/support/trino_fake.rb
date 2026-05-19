# frozen_string_literal: true

# Helpers for stubbing the Trino REST protocol with WebMock.
#
# The Trino client (trino-client gem) issues `POST <server>/v1/statement`
# with the SQL in the request body, then follows `nextUri` in successive
# GETs until `nextUri` is absent in the response. Each response carries
# `columns`, `data`, and `stats`.
#
# Usage:
#   include TrinoFake
#   stub_trino_query(
#     sql: "SELECT 1 AS n",
#     columns: [["n", "integer"]],
#     rows: [[1]],
#   )
module TrinoFake
  HOST = "trino.example.com:8090"
  BASE_URL = "http://#{HOST}".freeze
  SERVER = HOST

  def trino_config(overrides = {})
    {
      adapter: "trino",
      server: HOST,
      user: "tester",
      catalog: "test_catalog",
      schema: "test_schema",
      query_timeout: 10,
      plan_timeout: 5,
    }.merge(overrides)
  end

  def stub_trino_query(sql:, columns: [], rows: [], query_id: "q1") # rubocop:disable Metrics/MethodLength
    statement_url = "#{BASE_URL}/v1/statement"
    next_url = "#{BASE_URL}/v1/next/#{query_id}"

    initial_body = {
      id: query_id,
      infoUri: "#{BASE_URL}/ui/query.html?#{query_id}",
      nextUri: next_url,
      stats: { state: "RUNNING" },
    }
    final_body = {
      id: query_id,
      infoUri: "#{BASE_URL}/ui/query.html?#{query_id}",
      columns: columns.map { |name, type| trino_column(name, type) },
      data: rows,
      stats: { state: "FINISHED" },
    }

    WebMock.stub_request(:post, statement_url)
           .with(body: sql)
           .to_return(
             status: 200,
             body: initial_body.to_json,
             headers: { "Content-Type" => "application/json" }
           )

    WebMock.stub_request(:get, next_url)
           .to_return(
             status: 200,
             body: final_body.to_json,
             headers: { "Content-Type" => "application/json" }
           )
  end

  def stub_trino_error(sql:, error_name: "GENERIC_INTERNAL_ERROR", message: "boom", query_id: "q1")
    statement_url = "#{BASE_URL}/v1/statement"
    body = {
      id: query_id,
      infoUri: "#{BASE_URL}/ui/query.html?#{query_id}",
      stats: { state: "FAILED" },
      error: {
        message: message,
        errorCode: 1,
        errorName: error_name,
        errorType: "INTERNAL_ERROR",
        failureInfo: { type: "java.lang.RuntimeException", message: message },
      },
    }

    WebMock.stub_request(:post, statement_url)
           .with(body: sql)
           .to_return(
             status: 200,
             body: body.to_json,
             headers: { "Content-Type" => "application/json" }
           )
  end

private

  def trino_column(name, type)
    {
      name: name,
      type: type,
      typeSignature: {
        rawType: type.to_s.split("(").first,
        arguments: [],
      },
    }
  end
end
