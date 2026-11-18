# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "Schema cache" do
  let(:pool) { ActiveRecord::Base.connection_pool }

  before do
    pool.with_connection do |connection|
      connection.create_table(:places, force: true) do |t|
        t.string :name
        t.st_point :location, srid: 4326, geographic: true, has_z: true
      end
    end
  end

  after do
    pool.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
  end

  # Dumps the schema cache to a file of +extension+, drops the table, and
  # reads its columns back from the file.
  def columns_from_dump(extension)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "schema_cache#{extension}")
      pool.schema_cache.dump_to(path)
      pool.with_connection { |connection| connection.drop_table(:places) }

      ActiveRecord::ConnectionAdapters::SchemaReflection.new(path).columns_hash(pool, "places")
    end
  end

  def expect_spatial_columns(columns)
    expect(columns["location"]).to be_a(ActiveRecord::MysqlRgeo::SpatialColumn).and have_attributes(
      spatial?: true, srid: 4326, geographic?: true, has_z?: true, sql_type: "geography(PointZ,4326)"
    )
    expect(columns["name"]).to have_attributes(spatial?: false, type: :string)
  end

  it "keeps spatial columns in YAML" do
    expect_spatial_columns(columns_from_dump(".yml"))
  end

  it "keeps spatial columns in Marshal dumps" do
    expect_spatial_columns(columns_from_dump(".dump"))
  end

  it "keeps spatial columns in JSON" do
    unless defined?(ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer)
      skip "This Active Record has no JSON schema cache"
    end

    expect_spatial_columns(columns_from_dump(".json"))
  end
end
