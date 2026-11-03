# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "Spatial columns" do
  let(:place) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "places"

      def self.name = "Place"
    end
  end

  before do
    ActiveRecord::Base.with_connection do |connection|
      connection.execute(<<~SQL.squish)
        CREATE TABLE places (
          id bigint AUTO_INCREMENT PRIMARY KEY,
          name varchar(255) COMMENT 'Shown on the map',
          shape GEOMETRY,
          location POINT SRID 3857 COMMENT 'Where it is',
          coordinates POINT SRID 4326 COMMENT 'mysql2rgeo:geographic',
          elevation POINT COMMENT 'Measured on site mysql2rgeo:has_z mysql2rgeo:has_m',
          origin POINT COMMENT 'Start here mysql2rgeo:default:0101000000000000000000F03F0000000000000040',
          areas MULTIPOLYGON SRID 3857,
          collection GEOMETRYCOLLECTION
        )
      SQL
    end
  end

  after do
    ActiveRecord::Base.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
  end

  def column(name, table_name = "places")
    ActiveRecord::Base.with_connection { |connection| connection.columns(table_name) }.find { |c| c.name == name }
  end

  it "describes a spatial column with its geometric type and SRID" do
    expect(column("location")).to have_attributes(
      type: :geometry,
      sql_type: "geometry(Point,3857)",
      geometric_type: RGeo::Feature::Point,
      srid: 3857,
      geographic?: false,
      has_z?: false,
      has_m?: false,
      spatial?: true,
      limit: { type: "st_point", srid: 3857 }
    )
  end

  it "uses SRID 0 for columns without an SRID" do
    expect(column("shape")).to have_attributes(
      sql_type: "geometry(Geometry,0)",
      geometric_type: RGeo::Feature::Geometry,
      srid: 0,
      limit: { type: "geometry", srid: 0 }
    )
  end

  it "describes multi-geometry columns" do
    expect(column("areas")).to have_attributes(
      sql_type: "geometry(Multipolygon,3857)",
      geometric_type: RGeo::Feature::MultiPolygon,
      multi?: true,
      limit: { type: "multi_polygon", srid: 3857 }
    )
  end

  it "describes GEOMETRYCOLLECTION columns, which MySQL reports as geomcollection" do
    expect(column("collection")).to have_attributes(
      type: :geometry,
      geometric_type: RGeo::Feature::GeometryCollection,
      multi?: true,
      limit: { type: "geometry_collection", srid: 0 }
    )
  end

  it "reads a geographic column from its comment marker" do
    expect(column("coordinates")).to have_attributes(
      sql_type: "geography(Point,4326)",
      geographic?: true,
      srid: 4326,
      comment: nil,
      limit: { type: "st_point", srid: 4326, geographic: true }
    )
  end

  it "removes the whole default marker from the comment" do
    expect(column("origin").comment).to eq("Start here")
  end

  it "reads Z and M from their comment markers, and returns the comment without markers" do
    expect(column("elevation")).to have_attributes(
      sql_type: "geometry(PointZM,0)",
      has_z?: true,
      has_m?: true,
      comment: "Measured on site",
      limit: { type: "st_point", srid: 0, has_z: true, has_m: true }
    )
  end

  it "reads the SRID of a table named with its database" do
    database = ActiveRecord::Base.with_connection(&:current_database)

    expect(column("location", "#{database}.places").srid).to eq(3857)
  end

  it "leaves non-spatial columns as Rails builds them" do
    expect(column("name")).to be_an_instance_of(ActiveRecord::ConnectionAdapters::MySQL::Column)
      .and have_attributes(type: :string, comment: "Shown on the map")
  end

  it "keeps its spatial details through YAML, as the schema cache stores it" do
    restored = YAML.unsafe_load(YAML.dump(column("coordinates")))

    expect(restored).to eq(column("coordinates"))
      .and have_attributes(srid: 4326, geographic?: true, geometric_type: RGeo::Feature::Point)
  end

  it "is not equal to a column with another SRID" do
    expect(column("location")).not_to eq(column("shape"))
  end

  describe "model attributes" do
    it "assigns WKT with the column's SRID" do
      record = place.new(location: "POINT(1 2)")

      expect(record.location).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
    end

    it "reads geographic columns with a geographic factory" do
      ActiveRecord::Base.with_connection do |connection|
        connection.execute(
          "INSERT INTO places (coordinates) VALUES (ST_GeomFromText('POINT(-122 47)', 4326, 'axis-order=long-lat'))"
        )
      end

      expect(place.last.coordinates).to have_attributes(longitude: -122.0, latitude: 47.0, srid: 4326)
    end
  end
end
