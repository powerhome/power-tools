# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::FileOutput do
  include DatabaseHelper

  subject(:output) { described_class.new(path: export_path, target_database: dump_db_name) }

  let(:export_path) { File.join(Dir.tmpdir, "data_taster_file_output_#{Process.pid}.sql") }
  let(:users_yaml) { File.join(__dir__, "..", "..", "fixtures", "full_users_dump_tables.yml") }

  after do
    FileUtils.rm_f(export_path)
    DataTaster.reset!
  end

  describe "#run_sanitization?" do
    it "does not run post-export UPDATE sanitization" do
      expect(output.run_sanitization?).to eq(false)
    end
  end

  describe "#default_data" do
    it "does not add default confection entries" do
      expect(output.default_data).to eq({})
    end
  end

  describe "#target_database" do
    it "stores the configured dump database name" do
      expect(output.target_database).to eq(dump_db_name)
    end
  end

  describe "#qualified_table_name" do
    it "wraps the table name in backticks" do
      expect(output.qualified_table_name("users")).to eq("`users`")
    end

    it "escapes backticks in table names" do
      expect(output.qualified_table_name("user`s")).to eq("`user``s`")
    end
  end

  describe "file lifecycle" do
    it "writes FK toggles, statements, and closes the file" do
      output.send(:start_export)
      output.write_statement("SELECT 1")
      output.write_raw("INSERT INTO `db`.`t` VALUES (1);")
      output.send(:finish_export)

      sql = File.read(export_path)
      expect(sql).to start_with("SET FOREIGN_KEY_CHECKS=0;\n")
      expect(sql).to include("SELECT 1;")
      expect(sql).to include("INSERT INTO `db`.`t` VALUES (1);")
      expect(sql).to end_with("SET FOREIGN_KEY_CHECKS=1;\n")
    end
  end

  describe "#sample!" do
    let(:source) { instance_double(DataTaster::MysqlSource, source_client: source_db_client, database: source_db_name) }
    let(:rows) do
      [
        { "id" => 1, "email" => "a@example.com" },
        { "id" => 2, "email" => "b@example.com" },
      ]
    end
    let(:query_result) do
      result = instance_double("Mysql2::Result")
      allow(result).to receive(:fields).and_return(%w[id email])
      allow(result).to receive(:field_types).and_return(%w[longlong varchar(255)])
      allow(result).to receive(:each) { |&block| rows.each(&block) }
      result
    end

    before do
      allow(DataTaster).to receive(:confection).and_return({ "users" => "1 = 1" })
      allow(source).to receive(:query).and_return(query_result)

      DataTaster.setup(
        source: source,
        output: output,
        list: [users_yaml]
      )
    end

    it "writes batched INSERT statements with masked sensitive columns" do
      output.sample!

      sql = File.read(export_path)
      expect(sql).to start_with("SET FOREIGN_KEY_CHECKS=0;\n")
      expect(sql).to include("INSERT INTO `users` (`id`, `email`) VALUES")
      expect(sql).to include("CONCAT('users_', 1, '@nitrophrg.com')")
      expect(sql).to include("CONCAT('users_', 2, '@nitrophrg.com')")
      expect(sql).not_to include("'a@example.com'")
      expect(sql).not_to include("'b@example.com'")
      expect(sql).not_to match(/UPDATE `users` SET/)
      expect(sql).to end_with("SET FOREIGN_KEY_CHECKS=1;\n")
    end

    it "skips tables with an empty payload" do
      allow(DataTaster).to receive(:confection).and_return({ "users" => DataTaster::SKIP_CODE })

      output.sample!

      sql = File.read(export_path)
      expect(sql).not_to include("INSERT INTO `users`")
    end

    context "when more rows than BATCH_SIZE" do
      let(:rows) { Array.new(DataTaster::Sanitizer::BATCH_SIZE + 1) { |i| { "id" => i } } }
      let(:query_result) do
        result = instance_double("Mysql2::Result")
        allow(result).to receive(:fields).and_return(["id"])
        allow(result).to receive(:field_types).and_return(["longlong"])
        allow(result).to receive(:each) { |&block| rows.each(&block) }
        result
      end

      it "writes multiple INSERT batches" do
        output.sample!

        sql = File.read(export_path)
        expect(sql.scan("INSERT INTO `users` (`id`) VALUES").size).to eq(2)
      end
    end
  end
end
