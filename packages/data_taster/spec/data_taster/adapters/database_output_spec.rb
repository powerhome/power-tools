# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::DatabaseOutput do
  include DatabaseHelper

  subject(:output) { described_class.new(target_client: target_client) }

  let(:target_client) { dump_db_client }

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
      expect(output).to receive(:safe_execute).with("SELECT 1").and_call_original

      output.write_statement("SELECT 1")
    end
  end

  describe "#write_raw" do
    it "delegates to write_statement" do
      expect(output).to receive(:write_statement).with("RAW SQL")

      output.write_raw("RAW SQL")
    end
  end

  describe "#import_table" do
    let(:collection) { instance_double(DataTaster::Collection, assemble: payload) }

    context "when the table is skipped" do
      let(:payload) { {} }

      it "drops the table" do
        expect(output).to receive(:safe_execute)
          .with("DROP TABLE IF EXISTS #{dump_db_name}.users")
          .and_call_original

        output.import_table(collection, "users")
      end
    end

    context "when the table has export data" do
      let(:payload) { { select: "SELECT 1", sanitize: { "email" => "x@example.com" } } }
      let(:query_result) do
        result = instance_double("Mysql2::Result")
        allow(result).to receive(:fields).and_return(%w[id email])
        allow(result).to receive(:each) { |&block| [{ "id" => 1, "email" => "a@example.com" }].each(&block) }
        result
      end

      before do
        configure_data_taster
        allow(DataTaster).to receive(:confection).and_return({ "users" => "1 = 1" })
        allow(collection).to receive(:export_select_sql).and_return("SELECT * FROM source.users WHERE 1 = 1")
        allow(DataTaster.config.source).to receive(:query).and_return(query_result)
      end

      it "truncates and inserts sanitized rows" do
        allow(output).to receive(:safe_execute).and_call_original
        expect(output).to receive(:safe_execute).with("TRUNCATE TABLE #{dump_db_name}.users").ordered
        expect(output).to receive(:safe_execute) do |sql|
          expect(sql).to include("INSERT INTO `#{dump_db_name}`.`users` (`id`, `email`) VALUES")
          expect(sql).to include("'x@example.com'")
        end.ordered

        output.import_table(collection, "users")
      end
    end
  end

  describe "#sample!" do
    it "delegates table discovery to the source" do
      source = DataTaster::MysqlSource.new(source_client: source_db_client)
      allow(DataTaster).to receive(:config).and_return(
        Struct.new(:source).new(source)
      )
      expect(source).to receive(:table_names).and_return(["users"])
      allow(DataTaster::Collection).to receive(:new).and_return(
        instance_double(DataTaster::Collection, assemble: {})
      )
      expect(output).to receive(:safe_execute).and_call_original

      output.sample!
    end

    context "with a configured export", :integration do
      before { configure_data_taster }

      it "exports configured tables to the dump database" do
        setup_source_data

        expect { DataTaster.config.output.sample! }.not_to raise_error
      end
    end
  end
end
