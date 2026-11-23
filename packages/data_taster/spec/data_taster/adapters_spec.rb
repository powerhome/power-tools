# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Adapters do
  include DatabaseHelper

  describe ".wrap" do
    it "wraps Trilogy connections in the Trilogy adapter" do
      expect(described_class.wrap(trilogy_source_db_client)).to be_a(DataTaster::Adapters::Trilogy)
    end

    it "returns Mysql2 clients unchanged" do
      expect(described_class.wrap(source_db_client)).to be(source_db_client)
    end
  end
end
