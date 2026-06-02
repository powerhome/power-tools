# frozen_string_literal: true

require "spec_helper"
require "data_taster/sanitizer"

RSpec.describe DataTaster::Sanitizer do
  include DatabaseHelper

  let(:confection_stub) { double("confection") }

  def stub_config
    configure_data_taster
  end

  before do
    allow(DataTaster).to receive(:confection).and_return(confection_stub)
  end

  describe "#sanitization_rules" do
    context "when table is skippable" do
      it "returns an empty hash when confection is blank" do
        stub_config
        allow(confection_stub).to receive(:[]).with("users").and_return(nil)

        expect(described_class.new("users", {}).sanitization_rules).to eq({})
      end
    end

    context "when table is not skippable" do
      before do
        allow(confection_stub).to receive(:[]).with("users").and_return("some_config")
      end

      it "returns column names mapped to sanitization specs" do
        stub_config

        rules = described_class.new("users", {}).sanitization_rules

        expect(rules).to be_a(Hash)
        expect(rules["email"]).to include("CONCAT")
        expect(rules["encrypted_password"]).to eq("")
      end

      it "omits columns whose value is skip code" do
        stub_config
        rules = described_class.new("users", { "ssn" => DataTaster::SKIP_CODE }).sanitization_rules

        expect(rules).not_to have_key("ssn")
        expect(rules).to have_key("encrypted_password")
      end
    end
  end

  describe "#clean!" do
    context "when table is skippable" do
      before do
        allow(DataTaster).to receive(:safe_execute).and_return(true)
      end

      it "returns early when confection is blank" do
        stub_config
        allow(confection_stub).to receive(:[]).with("users").and_return(nil)

        sanitizer = described_class.new("users", {})
        result = sanitizer.clean!

        expect(result).to be_nil
      end

      it "returns early when confection is skip code" do
        stub_config
        allow(confection_stub).to receive(:[]).with("users").and_return(DataTaster::SKIP_CODE)

        sanitizer = described_class.new("users", {})
        result = sanitizer.clean!

        expect(result).to be_nil
      end
    end

    context "when table is not skippable" do
      before do
        allow(confection_stub).to receive(:[]).with("users").and_return("some_config")
      end

      it "executes default sanitization SQL on database export" do
        stub_config
        expect(DataTaster).to receive(:safe_execute).with(include("UPDATE test_dump.users"),
                                                          dump_db_client).at_least(:once).and_return(true)
        sanitizer = described_class.new("users", {})

        sanitizer.clean!
      end

      it "processes custom selections that override defaults" do
        stub_config
        allow(DataTaster).to receive(:safe_execute).and_return(true)
        custom_selections = { "ssn" => "custom_ssn_value" }
        sanitizer = described_class.new("users", custom_selections)

        result = sanitizer.clean!

        expect(result).to be_an(Array)
        expect(result).not_to be_empty

        sql_statements = result.join(" ")
        expect(sql_statements).to include("SET ssn = 'custom_ssn_value'")

        expect(sql_statements).to include("SET encrypted_password = NULL")
        expect(sql_statements).to include("SET notes = 'Redacted for privacy'")
      end

      it "handles errors and adds context warning" do
        stub_config
        allow(DataTaster).to receive(:safe_execute).and_raise(StandardError.new("Database error"))

        sanitizer = described_class.new("users", {})

        expect { sanitizer.clean! }.to raise_error(StandardError) do |raised_error|
          expect(raised_error.message).to include("Database error")
          expect(raised_error.message).to include("DATA TASTER WARNING")
        end
      end

      it "skips processing when SQL is skip code" do
        stub_config
        allow(DataTaster).to receive(:safe_execute).and_return(true)
        custom_selections = { "ssn" => DataTaster::SKIP_CODE }
        sanitizer = described_class.new("users", custom_selections)

        result = sanitizer.clean!

        expect(result).to be_an(Array)
        sql_statements = result.join(" ")
        expect(sql_statements).to include("SET encrypted_password = NULL")
        expect(sql_statements).to include("SET notes = 'Redacted for privacy'")
        expect(sql_statements).not_to include("SET ssn =")
      end
    end
  end

  describe "#defaults" do
    it "returns a hash of sanitization patterns" do
      stub_config
      sanitizer = described_class.new("users", {})
      defaults = sanitizer.send(:defaults)

      expect(defaults).to be_a(Hash)
      expect(defaults).to be_frozen

      # Check that we have the expected keys by looking for patterns that contain these terms
      encrypted_key = defaults.keys.find { |k| k.source.include?("encrypted") }
      ssn_key = defaults.keys.find { |k| k.source.include?("ssn") }
      dob_key = defaults.keys.find { |k| k.source.include?("dob") }
      note_key = defaults.keys.find { |k| k.source.include?("note") }
      compensation_key = defaults.keys.find { |k| k.source.include?("compensation") }

      expect(encrypted_key).to be_present
      expect(ssn_key).to be_present
      expect(dob_key).to be_present
      expect(note_key).to be_present
      expect(compensation_key).to be_present
    end

    it "includes table-specific email patterns" do
      stub_config
      sanitizer = described_class.new("users", {})
      defaults = sanitizer.send(:defaults)

      email_keys = defaults.keys.select { |k| k.source.include?("email") }
      expect(email_keys).not_to be_empty
    end
  end

  describe "#exceptions" do
    it "returns regex pattern for default exceptions" do
      stub_config
      sanitizer = described_class.new("users", {})
      exceptions = sanitizer.send(:exceptions)

      expect(exceptions).to be_a(String)
      expect(exceptions).to include("_id")
      expect(exceptions).to include("_at")
      expect(exceptions).to include("type")
    end

    it "includes extra exceptions when provided" do
      stub_config
      sanitizer = described_class.new("users", {})
      exceptions = sanitizer.send(:exceptions, extra: ["custom"])

      expect(exceptions).to include("custom")
    end
  end
end
