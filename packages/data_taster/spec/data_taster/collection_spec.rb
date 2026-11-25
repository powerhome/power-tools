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
      "SELECT * FROM #{source_db_name}.projects WHERE 1 = 1"
    )
  end

  describe "#export_select_sql" do
    it "returns a plain SELECT from source_db with the confection WHERE clause" do
      stub_config

      sql = DataTaster::Collection.new("projects").export_select_sql

      expect(sql).to eq("SELECT * FROM #{source_db_name}.projects WHERE 1 = 1")
    end
  end

  describe "#unqualified_names" do
    before { stub_config }

    def unqualified_names(ingredients)
      allow(DataTaster).to receive(:confection).and_return({ "phones" => ingredients })
      DataTaster::Collection.new("phones").unqualified_names
    end

    it "returns the names in the select: clause that no database comes before" do
      names = unqualified_names("phone_number_id IN (SELECT id FROM phone_numbers) AND owner_id IN " \
                                "(SELECT id FROM source.users) OR `kind` IN (SELECT kind FROM `source`.`kinds`)")

      expect(names).to include("phone_number_id", "phone_numbers", "source", "kind")
      expect(names).not_to include("users", "kinds")
    end

    it "reads the select: key of a table that also has sanitization" do
      names = unqualified_names({ "select" => "id IN (SELECT phone_id FROM calls)", "sanitize" => { "notes" => "x" } })

      expect(names).to include("calls")
    end

    it "is empty for a deprecated table" do
      expect(unqualified_names(DataTaster::SKIP_CODE)).to be_empty
    end
  end
end
