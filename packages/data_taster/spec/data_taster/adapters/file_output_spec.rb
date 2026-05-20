# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::FileOutput do
  include DatabaseHelper

  let(:export_path) { File.join(Dir.tmpdir, "data_taster_file_output_#{Process.pid}.sql") }

  after do
    FileUtils.rm_f(export_path)
  end

  it "writes FK toggles and closes the file" do
    output = described_class.new(path: export_path, target_database: dump_db_name)
    source = DataTaster::MysqlSource.new(client: source_db_client)

    output.begin_export!(source: source)
    output.write_statement("SELECT 1")
    output.write_raw("INSERT INTO `db`.`t` VALUES (1);")
    output.finish_export!

    sql = File.read(export_path)
    expect(sql).to start_with("SET FOREIGN_KEY_CHECKS=0;\n")
    expect(sql).to include("SELECT 1;")
    expect(sql).to include("INSERT INTO `db`.`t` VALUES (1);")
    expect(sql).to end_with("SET FOREIGN_KEY_CHECKS=1;\n")
  end

  it "honors execute for deprecated table drops" do
    output = described_class.new(path: export_path, target_database: dump_db_name, execute: false)

    expect(output.executes?).to be(false)
  end

  it "reports file export mode" do
    output = described_class.new(path: export_path, target_database: dump_db_name)

    expect(output.file_export?).to be(true)
    expect(output.database_export?).to be(false)
  end
end
