# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::DatabaseOutput do
  include DatabaseHelper

  subject(:output) { described_class.new(target_client: target_client) }

  let(:target_client) { dump_db_client }

  describe "#run_sanitization?" do
    it "runs post-export UPDATE sanitization" do
      expect(output.run_sanitization?).to eq(true)
    end
  end

  describe "#default_data" do
    it "includes schema_migrations by default" do
      expect(output.default_data).to eq({ "schema_migrations" => "1 = 1" })
    end
  end

  describe "#target_database" do
    it "reads from the client connection options" do
      expect(output.target_database).to eq(dump_db_name)
    end
  end

  context "with a Trilogy client" do
    let(:target_client) { trilogy_dump_db_client }

    it "reads the target database from the client connection options" do
      expect(output.target_database).to eq(dump_db_name)
    end

    it "runs statements with foreign key checks restored afterwards" do
      output.write_statement("SELECT 1")

      expect(output.target_client.query("SELECT @@FOREIGN_KEY_CHECKS AS checks").first["checks"]).to eq(1)
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
        allow(result).to receive(:field_types).and_return(%w[longlong varchar(255)])
        allow(result).to receive(:each) { |&block| [{ "id" => 1, "email" => "a@example.com" }].each(&block) }
        result
      end

      before do
        configure_data_taster
        allow(DataTaster).to receive(:confection).and_return({ "users" => "1 = 1" })
        allow(collection).to receive(:export_select_sql).and_return("SELECT * FROM source.users WHERE 1 = 1")
        allow(DataTaster.config.source).to receive(:query).and_return(query_result)
      end

      context "when the source is on another server" do
        before { allow(output).to receive(:copies_on_server?).and_return(false) }

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

      context "when the source is on the same server" do
        before { allow(output).to receive(:copies_on_server?).and_return(true) }

        it "copies the rows on the server, without reading them, then sanitizes the copy" do
          sanitizer = instance_double(DataTaster::Sanitizer, clean!: nil)
          allow(DataTaster::Sanitizer).to receive(:new).with("users", { "email" => "x@example.com" })
                                                       .and_return(sanitizer)
          allow(output).to receive(:safe_execute)

          output.import_table(collection, "users")

          expect(output).to have_received(:safe_execute).with("TRUNCATE TABLE #{dump_db_name}.users").ordered
          expect(output).to have_received(:safe_execute)
            .with("INSERT INTO #{dump_db_name}.users SELECT * FROM source.users WHERE 1 = 1").ordered
          expect(sanitizer).to have_received(:clean!)
          expect(DataTaster.config.source).not_to have_received(:query)
        end

        it "empties the table again when sanitizing the copy fails, so no unsanitized rows are left" do
          sanitizer = instance_double(DataTaster::Sanitizer)
          allow(sanitizer).to receive(:clean!).and_raise(Mysql2::Error, "boom")
          allow(DataTaster::Sanitizer).to receive(:new).and_return(sanitizer)
          allow(output).to receive(:safe_execute)

          expect { output.import_table(collection, "users") }.to raise_error(Mysql2::Error, "boom")
          expect(output).to have_received(:safe_execute).with("TRUNCATE TABLE #{dump_db_name}.users").twice
        end
      end
    end
  end

  describe "#copies_on_server?" do
    before { configure_data_taster }

    it "is true when the source and target are on the same server" do
      expect(output.copies_on_server?).to eq(true)
    end

    it "is true with Trilogy clients on the same server" do
      configure_data_taster(source_client: trilogy_source_db_client)
      trilogy_output = described_class.new(target_client: trilogy_dump_db_client)

      expect(trilogy_output.copies_on_server?).to eq(true)
    end

    it "is false when the servers differ" do
      allow(DataTaster.config.source.source_client).to receive(:query).and_return([{ "server_uuid" => "other" }])

      expect(output.copies_on_server?).to eq(false)
    end

    it "checks again when the output is set up with another source" do
      expect(output.copies_on_server?).to eq(true)

      configure_data_taster(source_client: double("source client", query: [{ "server_uuid" => "other" }]))

      expect(output.copies_on_server?).to eq(false)
    end

    it "is false when the server can't say which it is" do
      allow(target_client).to receive(:query).and_raise(Mysql2::Error, "Unknown system variable 'server_uuid'")

      expect(output.copies_on_server?).to eq(false)
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
        instance_double(DataTaster::Collection, assemble: {}, unqualified_names: [])
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
