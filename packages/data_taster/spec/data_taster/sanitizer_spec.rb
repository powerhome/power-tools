# frozen_string_literal: true

require "spec_helper"
require "data_taster/sanitizer"

RSpec.describe DataTaster::Sanitizer do
  let(:source_client_stub) { double("client") }
  let(:working_client_stub) { double("client", query_options: { database: "test_db" }) }
  let(:config_stub) { double("config", include_insert: false, working_client: working_client_stub) }
  let(:confection_stub) { double("confection") }
  let(:connection_stub) { double("connection") }
  let(:schema_cache_stub) { double("schema_cache") }
  let(:email_column) { double("column", name: "email") }
  let(:ssn_column) { double("column", name: "ssn") }
  let(:date_of_birth_column) { double("column", name: "date_of_birth") }
  let(:notes_column) { double("column", name: "notes") }
  let(:salary_column) { double("column", name: "compensation") }
  let(:encrypted_password_column) { double("column", name: "encrypted_password") }
  let(:email2_column) { double("column", name: "email2") }
  let(:address_column) { double("column", name: "address") }
  let(:address2_column) { double("column", name: "address2") }

  before do
    allow(DataTaster).to receive(:config).and_return(config_stub)
    allow(DataTaster).to receive(:confection).and_return(confection_stub)
    allow(DataTaster).to receive(:safe_execute).and_return(true)
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection_stub)
    allow(connection_stub).to receive(:schema_cache).and_return(schema_cache_stub)

    # Set up realistic table columns that will match the default patterns
    allow(schema_cache_stub).to receive(:columns).with("users").and_return([
                                                                             email_column, ssn_column, date_of_birth_column, notes_column,
                                                                             salary_column, encrypted_password_column, email2_column, address_column, address2_column
                                                                           ])
  end

  describe "#clean!" do
    context "when table is skippable" do
      it "returns early when confection is blank" do
        allow(confection_stub).to receive(:[]).with("users").and_return(nil)

        sanitizer = described_class.new("users", {})
        result = sanitizer.clean!

        expect(result).to be_nil
      end

      it "returns early when confection is skip code" do
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

      it "processes default selections when include_insert is false" do
        sanitizer = described_class.new("users", {})

        result = sanitizer.clean!

        expect(result).to be_an(Array)
        expect(result).not_to be_empty

        # Check that we get SQL for columns that match default patterns
        sql_statements = result.join(" ")
        expect(sql_statements).to include("UPDATE test_db.users")

        # Should have SQL for SSN (matches ssn pattern)
        expect(sql_statements).to include("SET ssn = '111111111'")

        # Should have SQL for encrypted_password (matches encrypted pattern)
        expect(sql_statements).to include("SET encrypted_password = NULL")

        # Should have SQL for notes (matches note pattern)
        expect(sql_statements).to include("SET notes = 'Redacted for privacy'")

        # Should have SQL for compensation (matches compensation pattern)
        expect(sql_statements).to include("SET compensation = 999999")
      end

      it "processes custom selections that override defaults" do
        custom_selections = { "ssn" => "custom_ssn_value" }
        sanitizer = described_class.new("users", custom_selections)

        result = sanitizer.clean!

        expect(result).to be_an(Array)
        expect(result).not_to be_empty

        # Check that custom selection overrides the default
        sql_statements = result.join(" ")
        expect(sql_statements).to include("SET ssn = 'custom_ssn_value'")

        # Should still have other default patterns
        expect(sql_statements).to include("SET encrypted_password = NULL")
        expect(sql_statements).to include("SET notes = 'Redacted for privacy'")
      end

      it "executes SQL when include_insert is true" do
        allow(config_stub).to receive(:include_insert).and_return(true)
        sanitizer = described_class.new("users", {})

        expect(DataTaster).to receive(:safe_execute).with(include("UPDATE")).at_least(:once)

        sanitizer.clean!
      end

      it "handles errors and adds context warning" do
        allow(config_stub).to receive(:include_insert).and_return(true)
        allow(DataTaster).to receive(:safe_execute).and_raise(StandardError.new("Database error"))

        sanitizer = described_class.new("users", {})

        # The sanitizer now properly concatenates the error message with the context warning
        expect { sanitizer.clean! }.to raise_error(StandardError) do |raised_error|
          expect(raised_error.message).to include("Database error")
          expect(raised_error.message).to include("DATA TASTER WARNING")
        end
      end

      it "skips processing when SQL is skip code" do
        # Use custom selection with skip code to test skip behavior
        custom_selections = { "ssn" => DataTaster::SKIP_CODE }
        sanitizer = described_class.new("users", custom_selections)

        result = sanitizer.clean!

        expect(result).to be_an(Array)
        # Should have other default patterns but not the skipped one
        sql_statements = result.join(" ")
        expect(sql_statements).to include("SET encrypted_password = NULL")
        expect(sql_statements).to include("SET notes = 'Redacted for privacy'")
        expect(sql_statements).not_to include("SET ssn =")
      end
    end
  end

  describe "#defaults" do
    it "returns a hash of sanitization patterns" do
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
      sanitizer = described_class.new("users", {})
      defaults = sanitizer.send(:defaults)

      # Look for email-related patterns
      email_keys = defaults.keys.select { |k| k.source.include?("email") }
      expect(email_keys).not_to be_empty
    end
  end

  describe "#exceptions" do
    it "returns regex pattern for default exceptions" do
      sanitizer = described_class.new("users", {})
      exceptions = sanitizer.send(:exceptions)

      expect(exceptions).to be_a(String)
      expect(exceptions).to include("_id")
      expect(exceptions).to include("_at")
      expect(exceptions).to include("type")
    end

    it "includes extra exceptions when provided" do
      sanitizer = described_class.new("users", {})
      exceptions = sanitizer.send(:exceptions, extra: ["custom"])

      expect(exceptions).to include("custom")
    end
  end
end
