# frozen_string_literal: true

require "spec_helper"
require "data_taster/detergent"

RSpec.describe DataTaster::Detergent do
  let(:output_stub) do
    double(
      "output",
      target_database: "test_db",
      export_mode: :database,
      qualified_table_name: "test_db.users"
    )
  end
  let(:config_stub) { double("config", output: output_stub) }

  before do
    allow(DataTaster).to receive(:config).and_return(config_stub)
    allow(DataTaster).to receive(:target_database).and_return("test_db")
    allow(DataTaster).to receive(:logger).and_return(double("logger", info: nil))
  end

  describe "#insert_value_expression" do
    let(:client) { double("client") }

    before do
      allow(client).to receive(:escape) { |s| s }
    end

    it "returns a literal SQL string for plain masked values" do
      detergent = described_class.new("users", "ssn", "111111111")
      row = { "id" => 1, "ssn" => "123-45-6789" }

      expect(detergent.insert_value_expression(row, client)).to eq("'111111111'")
    end

    it "substitutes row identifiers inside function expressions" do
      detergent = described_class.new("users", "email", "CONCAT('users_', id, '@nitrophrg.com')")
      row = { "id" => 1, "email" => "secret@example.com" }

      expect(detergent.insert_value_expression(row, client)).to eq("CONCAT('users_', 1, '@nitrophrg.com')")
    end

    it "returns NULL for blank replacement values" do
      detergent = described_class.new("users", "encrypted_password", "")
      row = { "id" => 1, "encrypted_password" => "x" }

      expect(detergent.insert_value_expression(row, client)).to eq("NULL")
    end

    it "returns skip code when value is skip code" do
      detergent = described_class.new("users", "email", DataTaster::SKIP_CODE)
      row = { "id" => 1 }

      expect(detergent.insert_value_expression(row, client)).to eq(DataTaster::SKIP_CODE)
    end
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

    context "when output is SQL file (not database export)" do
      let(:output_stub) do
        double(
          "output",
          target_database: "test_db",
          export_mode: :file,
          qualified_table_name: "`users`"
        )
      end

      it "uses only the quoted table name in UPDATE statements" do
        detergent = described_class.new("users", "email", "test@example.com")
        result = detergent.deliver

        expect(result).to include("UPDATE `users`")
        expect(result).not_to include("UPDATE test_db.users")
      end
    end
  end
end
