# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::DatabaseOutput do
  include DatabaseHelper

  let(:client) { dump_db_client }

  it "returns the target database from the client" do
    output = described_class.new(client: client)

    expect(output.target_database).to eq(dump_db_name)
  end

  it "executes SQL via write_statement" do
    output = described_class.new(client: client)

    expect(DataTaster).to receive(:safe_execute).with("SELECT 1", client)

    output.write_statement("SELECT 1")
  end

  it "reports database export mode" do
    output = described_class.new(client: client)

    expect(output.export_mode).to eq(:database)
  end

  it "qualifies table names with the target database" do
    output = described_class.new(client: client)

    expect(output.qualified_table_name("users")).to eq("#{dump_db_name}.users")
  end
end
