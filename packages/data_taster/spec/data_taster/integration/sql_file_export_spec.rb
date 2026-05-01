# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster SQL file export", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_users_dump_tables.yml") }
  let(:export_path) { File.join(Dir.tmpdir, "data_taster_sql_export_#{Process.pid}.sql") }

  before do
    DataTaster.config(
      source_client: source_db_client,
      working_client: dump_db_client,
      list: [yaml_path],
      include_insert: true,
      filename: File.expand_path(export_path)
    )
    setup_source_data
  end

  after do
    FileUtils.rm_f(export_path)
    DataTaster.reset!
  end

  describe "dump file content" do
    it "qualifies INSERTs and sanitizer UPDATEs with the working (restore target) DB, and does not mutate the source" do
      count_before = source_db_client.query("SELECT COUNT(*) AS cnt FROM users").first["cnt"]

      DataTaster.sample_to_sql_file!

      path = File.expand_path(DataTaster.config.filename)
      expect(path).to eq(File.expand_path(export_path))
      expect(File).to exist(path)

      count_after = source_db_client.query("SELECT COUNT(*) AS cnt FROM users").first["cnt"]
      expect(count_after).to eq(count_before)

      sql = File.read(path)
      expect(sql).to start_with("SET FOREIGN_KEY_CHECKS=0;\n")
      expect(sql).to include("SET FOREIGN_KEY_CHECKS=1;")

      quoted_dump_db = "`#{dump_db_name.gsub('`', '``')}`"
      expect(sql).to include("INSERT INTO #{quoted_dump_db}.`users`")

      expect(sql).to include("UPDATE #{dump_db_name}.users")

      expect(sql).to include("CONCAT('users_', id, '@nitrophrg.com')")
      expect(sql).to include("test@example.com")
    end
  end
end
