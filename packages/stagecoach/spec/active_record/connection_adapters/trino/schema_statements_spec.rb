# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::Trino::SchemaStatements do
  include TrinoFake

  let(:adapter) do
    ActiveRecord::ConnectionAdapters::TrinoAdapter.new(trino_config)
  end

  describe "#columns" do
    it "queries information_schema.columns and returns Trino::Column instances" do
      expected_sql = <<~SQL.strip
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_catalog = 'test_catalog'
          AND table_schema = 'test_schema'
          AND table_name = 'orders'
        ORDER BY ordinal_position
      SQL

      stub_trino_query(
        sql: expected_sql,
        columns: [%w[column_name varchar], %w[data_type varchar], %w[is_nullable varchar]],
        rows: [
          %w[id bigint NO],
          %w[name varchar YES],
          ["created_at", "timestamp(3)", "YES"],
        ]
      )

      columns = adapter.columns("orders")

      expect(columns.map(&:name)).to eq(%w[id name created_at])
      expect(columns.first.sql_type).to eq("bigint")
      expect(columns.first.null).to be false
      expect(columns[1].null).to be true
      expect(columns.last.cast_type).to be_a(ActiveModel::Type::DateTime)
    end
  end

  describe "#data_sources" do
    it "parses SHOW TABLES" do
      stub_trino_query(
        sql: "SHOW TABLES",
        columns: [%w[Table varchar]],
        rows: [["orders"], ["users"]]
      )

      expect(adapter.data_sources).to eq(%w[orders users])
    end
  end

  describe "#primary_key / #indexes / #foreign_keys" do
    it "always returns nil/empty (Trino has no PKs/indexes/FKs)" do
      expect(adapter.primary_key("anything")).to be_nil
      expect(adapter.indexes("anything")).to eq([])
      expect(adapter.foreign_keys("anything")).to eq([])
    end
  end
end
