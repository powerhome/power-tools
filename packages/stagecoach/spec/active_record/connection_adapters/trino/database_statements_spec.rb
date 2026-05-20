# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::Trino::DatabaseStatements do
  include TrinoFake

  let(:adapter) do
    ActiveRecord::ConnectionAdapters::TrinoAdapter.new(trino_config)
  end

  describe "#exec_query" do
    it "returns an ActiveRecord::Result with columns, rows, and column types" do
      stub_trino_query(
        sql: "SELECT id, name FROM users",
        columns: [%w[id integer], %w[name varchar]],
        rows: [[1, "Ada"], [2, "Grace"]]
      )

      result = adapter.exec_query("SELECT id, name FROM users")

      expect(result).to be_a(ActiveRecord::Result)
      expect(result.columns).to eq(%w[id name])
      expect(result.rows).to eq([[1, "Ada"], [2, "Grace"]])
      expect(result.column_types["id"]).to be_a(ActiveModel::Type::Integer)
      expect(result.column_types["name"]).to be_a(ActiveModel::Type::String)
    end

    it "refuses non-empty bind variables" do
      expect do
        adapter.exec_query("SELECT 1", "SQL", ["bound_value"])
      end.to raise_error(Stagecoach::Error, /bind variables are not supported/)
    end

    it "raises StatementInvalid on a Trino query error" do
      stub_trino_error(sql: "SELECT * FROM nope", message: "table nope does not exist")

      expect { adapter.exec_query("SELECT * FROM nope") }
        .to raise_error(ActiveRecord::StatementInvalid, /table nope does not exist/)
    end
  end

  describe "result handling" do
    it "concatenates rows across multiple Trino pages" do
      statement_url = "#{TrinoFake::BASE_URL}/v1/statement"
      page2_url = "#{TrinoFake::BASE_URL}/v1/next/q1/page2"
      page3_url = "#{TrinoFake::BASE_URL}/v1/next/q1/page3"
      column_spec = { name: "id", type: "integer", typeSignature: { rawType: "integer" } }

      WebMock.stub_request(:post, statement_url).with(body: "SELECT id FROM t")
             .to_return(
               status: 200,
               body: {
                 id: "q1",
                 nextUri: page2_url,
                 columns: [column_spec],
                 data: [[1]],
                 stats: { state: "RUNNING" },
               }.to_json,
               headers: { "Content-Type" => "application/json" }
             )

      WebMock.stub_request(:get, page2_url).to_return(
        status: 200,
        body: {
          id: "q1",
          nextUri: page3_url,
          columns: [column_spec],
          data: [[2], [3]],
          stats: { state: "RUNNING" },
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      WebMock.stub_request(:get, page3_url).to_return(
        status: 200,
        body: {
          id: "q1",
          columns: [column_spec],
          data: [[4]],
          stats: { state: "FINISHED" },
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      result = adapter.exec_query("SELECT id FROM t")
      expect(result.rows).to eq([[1], [2], [3], [4]])
    end

    it "handles an empty result set" do
      stub_trino_query(
        sql: "SELECT * FROM empty_table",
        columns: [%w[id integer]],
        rows: []
      )

      result = adapter.exec_query("SELECT * FROM empty_table")
      expect(result.columns).to eq(["id"])
      expect(result.rows).to eq([])
    end
  end

  describe "error mapping" do
    it "translates TrinoQueryTimeoutError to ActiveRecord::StatementTimeout" do
      allow(adapter.client).to receive(:query).and_raise(
        Trino::Client::TrinoQueryTimeoutError.new("Query exceeded maximum execution time of 60 seconds")
      )

      expect { adapter.exec_query("SELECT 1") }
        .to raise_error(ActiveRecord::StatementTimeout, /maximum execution time/)
    end

    it "translates TrinoHttpError to ActiveRecord::ConnectionFailed" do
      allow(adapter.client).to receive(:query).and_raise(
        Trino::Client::TrinoHttpError.new(503, "Service Unavailable")
      )

      expect { adapter.exec_query("SELECT 1") }
        .to raise_error(ActiveRecord::ConnectionFailed, /Service Unavailable/)
    end
  end

  describe "query metadata capture" do
    it "exposes last_query_id, last_query_info_uri, and last_query_stats after a query" do
      stub_trino_query(
        sql: "SELECT id FROM t",
        columns: [%w[id integer]],
        rows: [[1]],
        query_id: "metadata_q"
      )

      adapter.exec_query("SELECT id FROM t")

      expect(adapter.last_query_id).to eq("metadata_q")
      expect(adapter.last_query_info_uri).to include("metadata_q")
      expect(adapter.last_query_stats).to include(
        state: "FINISHED",
        queued_time_millis: 5,
        elapsed_time_millis: 25,
        cpu_time_millis: 15,
        wall_time_millis: 20
      )
    end

    it "returns nil for metadata before any query has run" do
      expect(adapter.last_query_id).to be_nil
      expect(adapter.last_query_info_uri).to be_nil
      expect(adapter.last_query_stats).to be_nil
    end
  end

  describe "slow-query notification" do
    it "emits stagecoach.slow_query when threshold is exceeded" do
      stub_trino_query(sql: "SELECT 1", columns: [%w[n integer]], rows: [[1]])

      adapter.instance_variable_set(:@slow_query_threshold, 0.0)

      payload = nil
      ActiveSupport::Notifications.subscribed(->(*args) { payload = args.last }, "stagecoach.slow_query") do
        adapter.execute("SELECT 1")
      end

      expect(payload).to include(sql: "SELECT 1")
      expect(payload[:duration]).to be >= 0
    end

    it "does not emit when threshold is not exceeded" do
      stub_trino_query(sql: "SELECT 1", columns: [%w[n integer]], rows: [[1]])

      adapter.instance_variable_set(:@slow_query_threshold, 1_000.0)

      emitted = false
      ActiveSupport::Notifications.subscribed(->(*_args) { emitted = true }, "stagecoach.slow_query") do
        adapter.execute("SELECT 1")
      end

      expect(emitted).to be false
    end

    it "carries sql and a numeric duration in the notification payload" do
      stub_trino_query(sql: "SELECT 2", columns: [%w[n integer]], rows: [[2]])
      adapter.instance_variable_set(:@slow_query_threshold, 0.0)

      payloads = []
      subscriber = ActiveSupport::Notifications.subscribe("stagecoach.slow_query") do |*args|
        payloads << args.last
      end
      adapter.execute("SELECT 2")
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(payloads.size).to eq(1)
      expect(payloads.first[:sql]).to eq("SELECT 2")
      expect(payloads.first[:duration]).to be_a(Numeric)
      expect(payloads.first[:duration]).to be >= 0
    end

    it "carries query_id and info_uri in the notification payload" do
      stub_trino_query(
        sql: "SELECT 3",
        columns: [%w[n integer]],
        rows: [[3]],
        query_id: "slow_q"
      )
      adapter.instance_variable_set(:@slow_query_threshold, 0.0)

      payload = nil
      ActiveSupport::Notifications.subscribed(->(*args) { payload = args.last }, "stagecoach.slow_query") do
        adapter.execute("SELECT 3")
      end

      expect(payload[:query_id]).to eq("slow_q")
      expect(payload[:info_uri]).to include("slow_q")
    end
  end
end
