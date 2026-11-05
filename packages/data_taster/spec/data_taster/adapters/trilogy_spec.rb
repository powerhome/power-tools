# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Adapters::Trilogy do
  include DatabaseHelper

  subject(:client) { described_class.new(trilogy_source_db_client) }

  describe "#query" do
    it "yields rows as hashes" do
      expect(client.query("SELECT 1 AS one, 'a' AS letter").to_a).to eq([{ "one" => 1, "letter" => "a" }])
    end

    it "returns the column names" do
      expect(client.query("SELECT 1 AS one, 'a' AS letter").fields).to eq(%w[one letter])
    end

    it "reports no column types" do
      expect(client.query("SELECT 1 AS one").field_types).to eq([])
    end
  end

  describe "#query_options" do
    it "returns the connected database" do
      expect(client.query_options[:database]).to eq(source_db_name)
    end
  end

  describe "#escape" do
    it "escapes values through the connection" do
      expect(client.escape("O'Brien")).to eq("O\\'Brien")
    end
  end
end
