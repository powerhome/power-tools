# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::MysqlSource do
  include DatabaseHelper

  subject(:source) { described_class.new(client: source_db_client) }

  it "delegates query to the client" do
    expect(source.query("SELECT 1 AS one").first["one"]).to eq(1)
  end

  it "returns the database name" do
    expect(source.database).to eq(source_db_name)
  end

  it "lists table names" do
    expect(source.table_names).to include("users")
  end
end
