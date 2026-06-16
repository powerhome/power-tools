# frozen_string_literal: true

require "spec_helper"
require "data_taster/detergent"

RSpec.describe DataTaster::Detergent do
  let(:source_client_stub) { double("client") }
  let(:working_client_stub) { double("client") }
  let(:config_stub) { double("config", working_client: working_client_stub) }

  before do
    allow(DataTaster).to receive(:config).and_return(config_stub)
    allow(working_client_stub).to receive(:query_options).and_return(database: "test_db")
    allow(DataTaster).to receive(:logger).and_return(double("logger", info: nil))
  end

  describe "#deliver" do
    it "generates SQL for string values" do
      detergent = described_class.new("users", "email", "test@example.com")
      result = detergent.deliver

      expect(result).to include("UPDATE test_db.users")
      expect(result).to include("SET email = 'test@example.com'")
      expect(result).to include("WHERE email IS NOT NULL")
      expect(result).to include("AND email <> ''")
    end

    it "generates SQL for date values" do
      detergent = described_class.new("users", "created_at", "2023-01-01")
      result = detergent.deliver

      expect(result).to include("UPDATE test_db.users")
      expect(result).to include("SET created_at = '2023-01-01'")
      expect(result).to include("WHERE created_at IS NOT NULL")
    end

    it "generates SQL for numeric values" do
      detergent = described_class.new("users", "age", 25)
      result = detergent.deliver

      expect(result).to include("UPDATE test_db.users")
      expect(result).to include("SET age = 25")
      expect(result).to include("WHERE age IS NOT NULL")
      expect(result).to include("AND age <> 25")
    end

    it "generates SQL for sanitize functions" do
      detergent = described_class.new("users", "name", "UPPER(name)")
      result = detergent.deliver

      expect(result).to include("UPDATE test_db.users")
      expect(result).to include("SET name = UPPER(name)")
      expect(result).to include("WHERE name IS NOT NULL")
      expect(result).to include("AND name <> UPPER(name)")
    end

    it "generates SQL for nil values" do
      detergent = described_class.new("users", "deleted_at", nil)
      result = detergent.deliver

      expect(result).to include("UPDATE test_db.users")
      expect(result).to include("SET deleted_at = NULL")
      expect(result).to include("WHERE deleted_at IS NOT NULL")
    end

    it "returns skip code when value is skip code" do
      detergent = described_class.new("users", "email", DataTaster::SKIP_CODE)
      result = detergent.deliver

      expect(result).to eq(DataTaster::SKIP_CODE)
    end
  end
end
