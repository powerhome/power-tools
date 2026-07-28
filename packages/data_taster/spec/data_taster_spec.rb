# frozen_string_literal: true

require "spec_helper"

describe DataTaster do
  after { DataTaster.reset! }

  it "has a version number" do
    expect(DataTaster::VERSION).not_to be nil
  end

  describe ".setup" do
    it "rebuilds confection when called again without reset!" do
      source = instance_double(DataTaster::MysqlSource)
      file_output = instance_double(DataTaster::FileOutput, default_data: {})
      database_output = instance_double(
        DataTaster::DatabaseOutput,
        default_data: { "schema_migrations" => "1 = 1" }
      )
      list = [File.join(__dir__, "fixtures", "data_taster_export_tables.yml")]

      DataTaster.setup(source: source, output: file_output, list: list)
      first_confection = DataTaster.confection

      expect(first_confection).not_to include("schema_migrations")
      expect(first_confection).to include("projects")

      DataTaster.setup(source: source, output: database_output, list: list)

      expect(DataTaster.confection).to include("schema_migrations" => "1 = 1")
      expect(DataTaster.confection).to include("projects")
      expect(DataTaster.confection).not_to equal(first_confection)
    end
  end
end
