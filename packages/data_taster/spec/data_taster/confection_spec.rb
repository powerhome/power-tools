# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Confection do
  let(:existing_yml) { File.join(File.join(__dir__, "..", "fixtures"), "data_taster_export_tables.yml") }
  let(:missing_yml) { File.join(File.join(__dir__, "..", "fixtures"), "does_not_exist_export_tables.yml") }

  before do
    DataTaster.config(
      months: nil,
      list: [missing_yml, existing_yml],
      source_client: source_db_client,
      working_client: dump_db_client,
      include_insert: false
    )
    DataTaster.instance_variable_set(:@confection, nil)
  end

  after do
    DataTaster.instance_variable_set(:@confection, nil)
    DataTaster.instance_variable_set(:@config, nil)
  end

  it "merges YAML from existing paths and ignores missing files" do
    result = described_class.new.assemble

    expect(result).to include("schema_migrations" => "1 = 1")
    expect(result).to include("projects" => "1 = 1")
  end
end
