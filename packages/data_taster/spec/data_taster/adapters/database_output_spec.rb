# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::DatabaseOutput do
  include DatabaseHelper

  let(:client) { dump_db_client }

  it "returns the target database from the client" do
    output = described_class.new(client: client)

    expect(output.target_database).to eq(dump_db_name)
  end

  it "executes SQL when execute is true" do
    configure_data_taster(execute: true)
    output = described_class.new(client: client, execute: true)

    expect(DataTaster).to receive(:safe_execute).with("SELECT 1", client)

    output.write_statement("SELECT 1")
  end

  it "logs SQL without executing when execute is false" do
    output = described_class.new(client: client, execute: false)
    logger = instance_double(Logger, info: nil)
    allow(DataTaster).to receive(:logger).and_return(logger)

    expect(DataTaster).not_to receive(:safe_execute)

    output.write_statement("SELECT 1")

    expect(logger).to have_received(:info).with("SELECT 1")
  end

  it "reports database export mode" do
    output = described_class.new(client: client)

    expect(output.database_export?).to be(true)
    expect(output.file_export?).to be(false)
  end
end
