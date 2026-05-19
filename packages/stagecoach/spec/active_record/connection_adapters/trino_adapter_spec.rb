# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::TrinoAdapter do
  include TrinoFake

  subject(:adapter) { described_class.new(trino_config) }

  describe "capabilities" do
    it "reports the Trino adapter name" do
      expect(adapter.adapter_name).to eq("Trino")
    end

    it "is not transactional" do
      expect(adapter.supports_transactions?).to be false
      expect(adapter.supports_savepoints?).to be false
      expect(adapter.supports_lazy_transactions?).to be false
    end

    it "does not use prepared statements" do
      expect(adapter.prepared_statements).to be false
    end

    it "does not support migrations or DDL" do
      expect(adapter.supports_migrations?).to be false
      expect(adapter.supports_ddl_transactions?).to be false
    end
  end

  describe "#active? / #disconnect! / #reconnect!" do
    it "starts active and survives disconnect/reconnect" do
      expect(adapter.active?).to be true
      adapter.disconnect!
      expect(adapter.active?).to be false
      adapter.reconnect!
      expect(adapter.active?).to be true
    end
  end

  describe "configuration validation" do
    it "raises if a required key is missing" do
      bad = trino_config.except(:host)
      expect { described_class.new(bad) }
        .to raise_error(Stagecoach::ConfigurationError, /host/)
    end
  end

  describe "#lookup_cast_type" do
    it "looks up by Trino sql_type string" do
      expect(adapter.lookup_cast_type("varchar")).to be_a(ActiveModel::Type::String)
      expect(adapter.lookup_cast_type("bigint")).to be_a(ActiveModel::Type::Integer)
    end
  end
end
