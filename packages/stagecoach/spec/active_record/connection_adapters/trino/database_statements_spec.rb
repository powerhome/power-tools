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
  end
end
