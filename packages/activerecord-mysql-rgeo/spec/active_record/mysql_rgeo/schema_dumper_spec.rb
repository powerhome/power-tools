# frozen_string_literal: true

require "spec_helper"
require "stringio"
require_relative "../../support/upstream_places"

RSpec.describe "schema.rb" do
  # activerecord-mysql2rgeo-adapter dumps spatial defaults as RGeo#inspect,
  # which is not valid Ruby, and leaves the default's hex in the comment. This
  # gem dumps the default as WKT instead.
  broken_default = /^    t\.geometry "origin".*\n/
  fixed_default = %(    t.geometry "origin", limit: {type: "st_point", srid: 3857}, default: "POINT (1.0 2.0)"\n)

  let(:expected_schema) { UpstreamPlaces.schema.sub(broken_default, fixed_default) }

  after do
    connection.drop_table(:places, if_exists: true)
  end

  def connection
    ActiveRecord::Base.lease_connection
  end

  def show_create_table
    connection.select_rows("SHOW CREATE TABLE places").first.last
  end

  # The create_table block for places. Ruby before 3.4 inspects hashes as
  # {:type=>"st_point"}; the fixtures were recorded with Ruby 3.4.
  def dump
    io = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, io)
    io.string[/^  create_table "places".*?^  end\n/m].gsub(/:(\w+)=>/, '\1: ')
  end

  def load_schema(schema)
    ActiveRecord::Migration.suppress_messages { ActiveRecord::Schema.new.instance_eval(schema) }
  end

  it "creates exactly the table activerecord-mysql2rgeo-adapter creates" do
    UpstreamPlaces.create_table(connection)

    expect(show_create_table).to eq(UpstreamPlaces.create_table_sql)
  end

  it "dumps a table created by activerecord-mysql2rgeo-adapter as it does, with a loadable default" do
    connection.execute(UpstreamPlaces.create_table_sql)

    expect(dump).to eq(expected_schema)
  end

  it "loads the dump into the same table activerecord-mysql2rgeo-adapter creates" do
    load_schema(expected_schema)

    expect(show_create_table).to eq(UpstreamPlaces.create_table_sql)
  end

  it "leaves connection.indexes as Rails reports it: type :spatial, no using" do
    UpstreamPlaces.create_table(connection)

    expect(connection.indexes(:places).first).to have_attributes(type: :spatial, using: nil)
  end

  it "dumps the loaded schema unchanged" do
    load_schema(expected_schema)

    expect(dump).to eq(expected_schema)
  end
end
