# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Collection do
  include DatabaseHelper

  let(:test_yaml_path) { File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml") }

  def stub_config(
    months: nil,
    list: [test_yaml_path]
  )
    configure_data_taster(months: months, list: list)
  end

  it "has '1 == 1' where clause for full table dump tables" do
    stub_config

    result = DataTaster::Collection.new("projects").assemble

    expect(result[:select]).to eq(
      "INSERT INTO #{dump_db_name}.projects SELECT * FROM #{source_db_name}.projects WHERE 1 = 1"
    )
  end

  describe "#export_select_sql" do
    it "returns a plain SELECT from source_db with the confection WHERE clause" do
      stub_config

      sql = DataTaster::Collection.new("projects").export_select_sql

      expect(sql).to eq("SELECT * FROM #{source_db_name}.projects WHERE 1 = 1")
    end
  end
end
