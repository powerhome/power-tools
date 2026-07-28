# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster SQL file export", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_users_dump_tables.yml") }
  let(:export_path) { File.join(Dir.tmpdir, "data_taster_sql_export_#{Process.pid}.sql") }

  before do
    configure_data_taster(
      list: [yaml_path],
      path: File.expand_path(export_path),
      target_database: dump_db_name
    )
    setup_source_data
  end

  after do
    FileUtils.rm_f(export_path)
    DataTaster.reset!
  end

  describe "dump file content" do
    it "writes masked INSERTs with quoted table, no sanitizer UPDATEs, and does not mutate the source" do
      count_before = source_db_client.query("SELECT COUNT(*) AS cnt FROM users").first["cnt"]

      DataTaster.sample!

      path = File.expand_path(DataTaster.config.output.path)
      expect(path).to eq(File.expand_path(export_path))
      expect(File).to exist(path)

      count_after = source_db_client.query("SELECT COUNT(*) AS cnt FROM users").first["cnt"]
      expect(count_after).to eq(count_before)

      sql = File.read(path)
      expect(sql).to start_with("SET FOREIGN_KEY_CHECKS=0;\n")
      expect(sql).to include("SET FOREIGN_KEY_CHECKS=1;")

      quoted_dump_db = "`#{dump_db_name.gsub('`', '``')}`"
      expect(sql).to include("INSERT INTO `users`")
      expect(sql).not_to include("INSERT INTO #{quoted_dump_db}.`users`")

      expect(sql).not_to match(/UPDATE `users` SET/)
      expect(sql).not_to include("UPDATE #{dump_db_name}.users")

      expect(sql).to include("CONCAT('users_', 1, '@nitrophrg.com')")
      expect(sql).not_to include("test@example.com")
      expect(sql).not_to include("test2@example.com")
      expect(sql).not_to include("123-45-6789")
      expect(sql).not_to include("Private notes")
    end
  end
end
