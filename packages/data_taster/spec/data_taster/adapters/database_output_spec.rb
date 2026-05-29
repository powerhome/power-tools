# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::DatabaseOutput do
  include DatabaseHelper

  subject(:output) { described_class.new(client: client) }

  let(:client) { dump_db_client }

  describe "#export_mode" do
    it "is database export" do
      expect(output.export_mode).to eq(:database)
    end
  end

  describe "#target_database" do
    it "reads from the client connection options" do
      expect(output.target_database).to eq(dump_db_name)
    end
  end

  describe "#qualified_table_name" do
    it "prefixes the table with the target database" do
      expect(output.qualified_table_name("users")).to eq("#{dump_db_name}.users")
    end
  end

  describe "#write_statement" do
    it "runs SQL through safe_execute" do
      expect(DataTaster).to receive(:safe_execute).with("SELECT 1", client)

      output.write_statement("SELECT 1")
    end
  end

  describe "#write_raw" do
    it "delegates to write_statement" do
      expect(output).to receive(:write_statement).with("RAW SQL")

      output.write_raw("RAW SQL")
    end
  end

  describe "#export_table" do
    let(:collection) { instance_double(DataTaster::Collection, assemble: payload) }

    context "when the table is skipped" do
      let(:payload) { {} }

      it "drops the table" do
        expect(DataTaster).to receive(:safe_execute).with("DROP TABLE IF EXISTS users", client)

        output.export_table(collection, "users")
      end
    end

    context "when the table has export data" do
      let(:payload) { { select: "SELECT 1", sanitize: { "email" => "x@example.com" } } }
      let(:sanitizer) { instance_double(DataTaster::Sanitizer, clean!: nil) }

      it "truncates, copies data, and sanitizes" do
        expect(DataTaster).to receive(:safe_execute)
          .with("TRUNCATE TABLE #{dump_db_name}.users", client)
        expect(DataTaster).to receive(:safe_execute).with("SELECT 1", client)
        expect(DataTaster::Sanitizer).to receive(:new)
          .with("users", payload[:sanitize])
          .and_return(sanitizer)
        expect(sanitizer).to receive(:clean!)

        output.export_table(collection, "users")
      end
    end
  end

  describe "#sample!" do
    it "delegates table discovery to the source" do
      source = DataTaster::MysqlSource.new(client: source_db_client)
      allow(DataTaster).to receive(:config).and_return(
        Struct.new(:source).new(source)
      )
      expect(source).to receive(:table_names).and_return(["users"])
      allow(DataTaster::Collection).to receive(:new).and_return(
        instance_double(DataTaster::Collection, assemble: {})
      )
      expect(DataTaster).to receive(:safe_execute)

      output.sample!
    end

    context "with a configured export", :integration do
      before { configure_data_taster }

      it "exports configured tables to the dump database" do
        setup_source_data

        expect(DataTaster).to receive(:safe_execute).at_least(:once).and_call_original

        DataTaster.config.output.sample!
      end
    end
  end
end
