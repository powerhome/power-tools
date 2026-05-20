# frozen_string_literal: true

require "spec_helper"

# Defined at file scope so AR is satisfied with a named class.
class DiagnosticsTarget < ActiveRecord::Base
  self.table_name = "users"
end

RSpec.describe Stagecoach::Diagnostics do
  include TrinoFake

  before do
    ActiveRecord::Base.establish_connection(trino_config)

    stub_trino_query(
      sql: /information_schema\.columns/,
      columns: [%w[column_name varchar], %w[data_type varchar], %w[is_nullable varchar]],
      rows: [
        %w[id bigint NO],
        %w[name varchar YES],
      ],
      query_id: "schema_q"
    )

    stub_trino_query(
      sql: "SHOW TABLES",
      columns: [%w[Table varchar]],
      rows: [["users"]],
      query_id: "show_q"
    )

    stub_trino_query(
      sql: /SELECT.+FROM "users"/i,
      columns: [%w[id bigint]],
      rows: [[1]],
      query_id: "sample_q"
    )

    DiagnosticsTarget.reset_column_information
  end

  after do
    ActiveRecord::Base.connection_handler.clear_all_connections!(:all)
  end

  describe ".profile" do
    subject(:result) { described_class.profile(DiagnosticsTarget) }

    it "returns the expected hash keys" do
      expect(result.keys).to include(
        :schema_time, :query_time,
        :query_id, :info_uri,
        :queued_time_ms, :elapsed_time_ms, :cpu_time_ms, :wall_time_ms,
        :state
      )
    end

    it "reports schema_time and query_time as non-negative Floats" do
      expect(result[:schema_time]).to be_a(Float).and(be >= 0)
      expect(result[:query_time]).to be_a(Float).and(be >= 0)
    end

    it "reports the Trino query_id and info_uri of the sample SELECT" do
      expect(result[:query_id]).to eq("sample_q")
      expect(result[:info_uri]).to include("sample_q")
    end

    it "surfaces the Trino-side stats from StatementStats" do
      expect(result[:queued_time_ms]).to eq(5)
      expect(result[:elapsed_time_ms]).to eq(25)
      expect(result[:cpu_time_ms]).to eq(15)
      expect(result[:wall_time_ms]).to eq(20)
      expect(result[:state]).to eq("FINISHED")
    end
  end
end
