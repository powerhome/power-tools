# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Collection do
  let(:test_yaml_path) { File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml") }

  let(:skippable_yaml_path) { File.join(__dir__, "..", "fixtures", "skippable_and_deprecated_tables.yml") }

  def stub_config(
    months: nil,
    list: [test_yaml_path],
    include_insert: false
  )
    DataTaster.instance_variable_set(:@config, nil)
    DataTaster.instance_variable_set(:@confection, nil)
    DataTaster.config(months: months,
                      list: list,
                      source_client: source_db_client,
                      working_client: dump_db_client,
                      include_insert: include_insert)
  end

  it "has '1 == 1' where clause for full table dump tables" do
    stub_config

    result = DataTaster::Collection.new("projects").assemble

    expect(result[:select]).to eq("SELECT * FROM #{source_db_name}.projects WHERE 1 = 1")
  end

  it "returns an empty hash when the table name is underscore-prefixed (skip data and schema)" do
    stub_config(list: [skippable_yaml_path])

    expect(described_class.new("_ignored_by_prefix").assemble).to eq({})
  end

  it "returns an empty hash when the confection entry is the global skip code" do
    stub_config(list: [skippable_yaml_path])

    expect(described_class.new("deprecated_via_erb").assemble).to eq({})
  end

  it "prefixes the select with INSERT when include_insert is true" do
    stub_config(include_insert: true)

    result = described_class.new("projects").assemble
    expect(result[:select]).to include("INSERT INTO #{dump_db_name}.projects")
    expect(result[:select]).to include("SELECT * FROM #{source_db_name}.projects WHERE 1 = 1")
  end
end
