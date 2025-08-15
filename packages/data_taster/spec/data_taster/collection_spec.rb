# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Collection do
  let(:test_db_config) { test_database_config }
  let(:test_client) { Mysql2::Client.new(test_db_config) }
  let(:test_dump_db_config) { test_dump_database_config }
  let(:test_dump_client) {  Mysql2::Client.new(test_dump_db_config) }
  let(:test_yaml_path) { File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml") }

  def stub_config(
    months: nil,
    list: [test_yaml_path],
    source_client: test_client,
    working_client: test_dump_client,
    include_insert: false
  )
    DataTaster.config(months: months,
                      list: list,
                      source_client: source_client,
                      working_client: working_client,
                      include_insert: include_insert)
  end

  it "has '1 == 1' where clause for full table dump tables" do
    stub_config
    result = DataTaster::Collection.new("projects").assemble

    expect(result[:select]).to eq("SELECT * FROM test.projects WHERE 1 = 1")
  end
end
