# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::MysqlRgeo::Type::Spatial do
  describe ".parse_sql_type" do
    it "parses plain geometry and geography types" do
      expect(described_class.parse_sql_type("geometry")).to eq(["geometry", 0, false, false, false])
      expect(described_class.parse_sql_type("geography")).to eq(["geography", 0, false, false, true])
    end

    it "parses the geometric type and its Z and M flags" do
      expect(described_class.parse_sql_type("geography(Point)")).to eq(["Point", 0, false, false, true])
      expect(described_class.parse_sql_type("geography(PointM)")).to eq(["Point", 0, false, true, true])
      expect(described_class.parse_sql_type("geography(PointZ)")).to eq(["Point", 0, true, false, true])
      expect(described_class.parse_sql_type("geography(PointZM)")).to eq(["Point", 0, true, true, true])
      expect(described_class.parse_sql_type("geography(Polygon)")).to eq(["Polygon", 0, false, false, true])
      expect(described_class.parse_sql_type("geography(PolygonZ)")).to eq(["Polygon", 0, true, false, true])
      expect(described_class.parse_sql_type("geography(PolygonM)")).to eq(["Polygon", 0, false, true, true])
      expect(described_class.parse_sql_type("geography(PolygonZM)")).to eq(["Polygon", 0, true, true, true])
    end

    it "parses the SRID" do
      expect(described_class.parse_sql_type("geography(Point,4326)")).to eq(["Point", 4326, false, false, true])
      expect(described_class.parse_sql_type("geography(PolygonZ,4327)")).to eq(["Polygon", 4327, true, false, true])
      expect(described_class.parse_sql_type("geography(PointM,4328)")).to eq(["Point", 4328, false, true, true])
      expect(described_class.parse_sql_type("geography(PointZM,4329)")).to eq(["Point", 4329, true, true, true])
      expect(described_class.parse_sql_type("geometry(MultiPolygon,4326)"))
        .to eq(["MultiPolygon", 4326, false, false, false])
    end

    it "returns other types unchanged" do
      expect(described_class.parse_sql_type("x")).to eq(["x", 0, false, false, false])
      expect(described_class.parse_sql_type("foo")).to eq(["foo", 0, false, false, false])
      expect(described_class.parse_sql_type("foo(A,1234)")).to eq(["foo(A,1234)", 0, false, false, false])
    end
  end

  describe ".normalize_geo_type" do
    it "underscores multi-word geometric types" do
      expect(described_class.normalize_geo_type("GeometryCollection")).to eq("geometry_collection")
      expect(described_class.normalize_geo_type("linestring")).to eq("line_string")
      expect(described_class.normalize_geo_type("MultiLineString")).to eq("multi_line_string")
      expect(described_class.normalize_geo_type("multipoint")).to eq("multi_point")
      expect(described_class.normalize_geo_type("MULTIPOLYGON")).to eq("multi_polygon")
    end

    it "downcases single-word geometric types" do
      expect(described_class.normalize_geo_type("Point")).to eq("point")
      expect(described_class.normalize_geo_type("geometry")).to eq("geometry")
    end
  end

  describe "#type" do
    it "is :geometry for every spatial SQL type" do
      expect(described_class.new("geometry(Point,3857)").type).to eq(:geometry)
      expect(described_class.new("geography(Polygon,4326)").type).to eq(:geometry)
    end
  end

  describe "#deserialize" do
    subject(:type) { described_class.new("geometry(Point,3857)") }

    let(:factory) { RGeo::Cartesian.preferred_factory(srid: 3857) }
    let(:point) { factory.point(1.0, 2.0) }

    it "returns nil for nil" do
      expect(type.deserialize(nil)).to be_nil
    end

    it "reads MySQL's internal format: a little-endian SRID followed by WKB" do
      value = [3857].pack("V") + RGeo::WKRep::WKBGenerator.new(little_endian: true).generate(point)

      expect(type.deserialize(value)).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
    end

    it "takes the SRID from MySQL's internal format over the column's" do
      value = [4326].pack("V") + RGeo::WKRep::WKBGenerator.new(little_endian: true).generate(point)

      expect(type.deserialize(value).srid).to eq(4326)
    end

    it "reads WKT with the column's SRID" do
      expect(type.deserialize("POINT(1 2)")).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
    end

    it "reads EWKT with its own SRID" do
      expect(type.deserialize("SRID=4326;POINT(1 2)")).to have_attributes(x: 1.0, y: 2.0, srid: 4326)
    end

    it "reads hex WKB with the column's SRID" do
      hex = RGeo::WKRep::WKBGenerator.new(hex_format: true).generate(point)

      expect(type.deserialize(hex)).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
    end

    it "reads hex EWKB into the column's SRID, as activerecord-mysql2rgeo-adapter does" do
      hex = RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true)
                                     .generate(RGeo::Cartesian.preferred_factory(srid: 4326).point(1.0, 2.0))

      expect(type.deserialize(hex)).to have_attributes(x: 1.0, y: 2.0, srid: 3857)
    end

    it "returns RGeo values unchanged" do
      expect(type.deserialize(point)).to equal(point)
    end

    it "returns nil for text that is not a geometry" do
      expect(type.deserialize("POINT (x)")).to be_nil
    end
  end

  describe "#cast" do
    it "uses the factory registered for the column's geometric type and SRID" do
      factory = RGeo::Cartesian.simple_factory(srid: 3857)
      store = RGeo::ActiveRecord::SpatialFactoryStore.instance
      store.register(factory, geo_type: "point", srid: 3857)

      expect(described_class.new("geometry(Point,3857)").cast("POINT(1 2)").factory).to eq(factory)
    ensure
      store.clear
    end

    it "uses a geographic factory for geography types" do
      point = described_class.new("geography(Point,4326)").cast("POINT(-122 47)")

      expect(point).to have_attributes(longitude: -122.0, latitude: 47.0)
    end
  end
end
