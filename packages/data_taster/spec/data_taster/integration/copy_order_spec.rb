# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster copy order", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "copy_order_tables.yml") }

  before do
    setup_source_data
    source_db_client.query("INSERT INTO users (id, created_at, updated_at) VALUES (2, NOW(), NOW())")
    source_db_client.query("INSERT INTO orders (id, user_id) VALUES (1, 1), (2, 2)")
    configure_data_taster(list: [yaml_path])
  end

  after do
    source_db_client.query("TRUNCATE TABLE orders")
    dump_db_client.query("TRUNCATE TABLE orders")
  end

  def dumped_order_ids
    dump_db_client.query("SELECT id FROM orders ORDER BY id").map { |row| row["id"] }
  end

  it "copies a table after the table its select: clause names, so it reads the sampled rows" do
    DataTaster.sample!

    expect(dumped_order_ids).to eq([1])
  end

  context "when the source is on another server" do
    before { allow(DataTaster.config.output).to receive(:copies_on_server?).and_return(false) }

    it "reads the named table from the source" do
      DataTaster.sample!

      expect(dumped_order_ids).to eq([1, 2])
    end
  end
end
