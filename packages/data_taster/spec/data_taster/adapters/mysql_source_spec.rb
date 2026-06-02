# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::MysqlSource do
  include DatabaseHelper

  subject(:source) { described_class.new(source_client: source_db_client) }

  describe "#query" do
    it "delegates to the mysql client" do
      expect(source.query("SELECT 1 AS one").first["one"]).to eq(1)
    end
  end

  describe "#database" do
    it "returns the database from the client connection options" do
      expect(source.database).to eq(source_db_name)
    end
  end

  describe "#table_names" do
    it "lists tables from the source database" do
      expect(source.table_names).to include("users")
    end
  end
end
