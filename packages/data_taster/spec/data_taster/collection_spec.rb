# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Collection do
  let(:test_yaml_path) { File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml") }

  def stub_config(
    months: nil,
    list: [test_yaml_path]
  )
    DataTaster.config(months: months,
                      list: list,
                      source_client: source_db_client,
                      working_client: dump_db_client,
                      include_insert: false)
  end

  it "has '1 == 1' where clause for full table dump tables" do
    stub_config

    result = DataTaster::Collection.new("projects").assemble

    expect(result[:select]).to eq("SELECT * FROM #{source_db_name}.projects WHERE 1 = 1")
  end
end
