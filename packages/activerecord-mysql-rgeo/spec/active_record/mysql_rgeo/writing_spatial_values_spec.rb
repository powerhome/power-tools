# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Writing spatial values" do
  let(:place) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "places"

      def self.name = "Place"
    end
  end

  let(:web_mercator) { RGeo::Cartesian.preferred_factory(srid: 3857) }

  before do
    ActiveRecord::Base.with_connection do |connection|
      connection.execute(<<~SQL.squish)
        CREATE TABLE places (
          id bigint AUTO_INCREMENT PRIMARY KEY,
          shape GEOMETRY,
          location POINT SRID 3857,
          coordinates POINT SRID 4326 COMMENT 'mysql2rgeo:geographic',
          areas MULTIPOLYGON
        )
      SQL
    end
  end

  after do
    ActiveRecord::Base.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
  end

  def select_value(sql)
    ActiveRecord::Base.with_connection { |connection| connection.select_value(sql) }
  end

  it "saves an RGeo geometry" do
    record = place.create!(location: web_mercator.point(1.0, 2.0))

    expect(place.find(record.id).location).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
  end

  it "saves WKT with the column's SRID" do
    record = place.create!(location: "POINT(1 2)")

    expect(place.find(record.id).location).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
  end

  it "saves changes to a geometry" do
    record = place.create!(location: "POINT(1 2)")
    record.update!(location: "POINT(3 4)")

    expect(place.find(record.id).location).to have_attributes(x: 3.0, y: 4.0)
  end

  it "stores SRID 4326 values longitude first" do
    place.create!(coordinates: RGeo::Geographic.spherical_factory(srid: 4326).point(-122, 47))

    expect(select_value("SELECT ST_Longitude(coordinates) FROM places")).to be_within(1e-9).of(-122.0)
    expect(place.last.coordinates).to have_attributes(longitude: -122.0, latitude: 47.0)
  end

  context "with an SRID 0 column" do
    it "round-trips multi-geometries" do
      wkt = "MULTIPOLYGON (((0.0 0.0, 0.0 10.0, 10.0 10.0, 10.0 0.0, 0.0 0.0)), " \
            "((20.0 20.0, 20.0 30.0, 30.0 30.0, 30.0 20.0, 20.0 20.0)))"
      record = place.create!(areas: wkt)

      areas = place.find(record.id).areas

      # Compare through the same factory: GEOS and pure-Ruby factories format WKT differently.
      expect(areas).to have_attributes(srid: 0, as_text: areas.factory.parse_wkt(wkt).as_text)
    end

    it "lets a generic geometry column hold any geometric type" do
      record = place.create!(shape: "POLYGON ((0.0 0.0, 0.0 10.0, 10.0 10.0, 10.0 0.0, 0.0 0.0))")

      expect(RGeo::Feature::Polygon.check_type(place.find(record.id).shape)).to be(true)
    end

    it "saves geometries of another SRID with SRID 0" do
      record = place.create!(shape: web_mercator.point(1.0, 2.0))

      expect(place.find(record.id).shape).to have_attributes(x: 1.0, y: 2.0, srid: 0)
    end
  end

  it "saves NULL for WKT that is not a geometry" do
    record = place.create!(location: "POINT (x)")

    expect(place.find(record.id).location).to be_nil
  end

  it "lets MySQL reject a geometry of the wrong type" do
    expect { place.create!(location: "LINESTRING(1 2, 3 4)") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "raises ArgumentError for values that are not geometries" do
    expect { place.create!(location: 42) }.to raise_error(ArgumentError, /not a geometry/)
  end

  it "finds records by a geometry" do
    record = place.create!(location: "POINT(1 2)")

    expect(place.where(location: web_mercator.point(1.0, 2.0)).pluck(:id)).to eq([record.id])
  end

  describe "spatial attribute types" do
    let(:place) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "places"

        attribute :spot, :st_point, srid: 3857
        attribute :spot_z, :st_point, has_z: true, srid: 3509
        attribute :spot_m, :st_point, has_m: true, srid: 3509
        attribute :area, :st_polygon, srid: 3857
        attribute :path, :line_string, srid: 3857
        attribute :route, :line_string, geographic: true, srid: 4326
        attribute :spots, :multi_point, srid: 3857
        attribute :paths, :multi_line_string, srid: 3857
        attribute :areas_attribute, :multi_polygon, srid: 3857

        def self.name = "Place"
      end
    end

    it "casts WKT with the attribute's options" do
      record = place.new(
        spot: "POINT(0 0)",
        spot_z: "POINT(0 0 1)",
        spot_m: "POINT(0 0 2)",
        area: "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))",
        path: "LINESTRING(0 0, 0 1, 1 1, 1 0, 0 0)",
        spots: "MULTIPOINT((0 0), (1 1))",
        paths: "MULTILINESTRING((0 0, 1 1))",
        areas_attribute: "MULTIPOLYGON(((0 0, 0 1, 1 1, 0 0)))"
      )

      expect(record.spot).to have_attributes(srid: 3857, x: 0.0, y: 0.0)
      expect(record.spot_z).to have_attributes(srid: 3509, z: 1.0)
      expect(record.spot_m).to have_attributes(srid: 3509, m: 2.0)
      expect([record.area, record.path, record.spots, record.paths, record.areas_attribute].map(&:srid))
        .to all(eq(3857))
    end

    it "uses a geographic factory for geographic attributes" do
      record = place.new(route: "LINESTRING(-75.165222 39.952583, -73.561668 45.508888)")

      expect(record.route.factory).to be_a(RGeo::Geographic::Factory)
    end

    it "registers the types for MySQL adapters only" do
      expect(ActiveRecord::Type.lookup(:st_point, adapter: TestDatabase.adapter.to_sym))
        .to be_a(ActiveRecord::MysqlRgeo::Type::Spatial)
      expect { ActiveRecord::Type.lookup(:st_point, adapter: :postgresql) }.to raise_error(ArgumentError)
    end

    it "casts columns selected under another name" do
      place.create!(location: "POINT(1 2)")

      expect(place.select("places.location AS spot").first.spot).to have_attributes(x: 1.0, srid: 3857)
    end
  end
end
