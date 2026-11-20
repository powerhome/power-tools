# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Spatial queries" do
  let(:place) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "places"

      def self.name = "Place"
    end
  end

  let(:places) { place.arel_table }
  let(:web_mercator) { RGeo::Cartesian.preferred_factory(srid: 3857) }
  let(:spherical) { RGeo::Geographic.spherical_factory(srid: 4326) }

  before do
    ActiveRecord::Base.with_connection do |connection|
      connection.create_table(:places, force: true) do |t|
        t.st_point :location, srid: 3857
        t.st_point :coordinates, srid: 4326, geographic: true
        t.multi_point :stops, srid: 3857
        t.line_string :path, srid: 3857
      end
    end
  end

  after do
    ActiveRecord::Base.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
  end

  describe "equality" do
    let!(:record) { place.create!(location: web_mercator.point(1, 2)) }

    it "finds records by a point" do
      expect(place.find_by(location: web_mercator.point(1, 2))).to eq(record)
      expect(place.where(location: web_mercator.point(2, 2))).to be_empty
    end

    it "finds records by a multi-point" do
      record.update!(stops: web_mercator.multi_point([web_mercator.point(1, 2)]))

      expect(place.find_by(stops: web_mercator.multi_point([web_mercator.point(1, 2)]))).to eq(record)
    end

    it "finds records by EWKT" do
      expect(place.find_by(location: "SRID=3857;POINT(1 2)")).to eq(record)
      expect(place.find_by(location: "SRID=3857;POINT(2 2)")).to be_nil
    end
  end

  describe "spatial functions" do
    it "takes EWKT arguments" do
      record = place.create!(location: web_mercator.point(1, 2))

      expect(place.find_by(places[:location].st_distance("SRID=3857;POINT(2 3)").lt(2))).to eq(record)
      expect(place.find_by(places[:location].st_distance("SRID=3857;POINT(2 3)").gt(2))).to be_nil
    end

    it "takes a constant geometry as the receiver" do
      record = place.create!(location: web_mercator.point(1, 2))
      query_point = RGeo::WKRep::WKTParser.new(nil, support_ewkt: true).parse("SRID=3857;POINT(2 3)")

      expect(place.find_by(Arel.spatial(query_point).st_distance(places[:location]).lt(2))).to eq(record)
      expect(place.find_by(Arel.spatial(query_point).st_distance(places[:location]).gt(2))).to be_nil
    end

    it "measures line strings" do
      record = place.create!(path: web_mercator.line(web_mercator.point(1, 2), web_mercator.point(3, 2)))

      expect(place.find_by(places[:path].st_length.eq(2))).to eq(record)
      expect(place.find_by(places[:path].st_length.gt(3))).to be_nil
    end

    it "takes RGeo geometries as arguments" do
      record = place.create!(path: "LINESTRING(1 2, 2 2, 3 2)")

      expect(place.find_by(places[:path].st_contains(web_mercator.point(2, 2)))).to eq(record)
      expect(place.find_by(places[:path].st_contains(web_mercator.point(0, 2)))).to be_nil
    end

    it "takes bounding boxes as arguments" do
      record = place.create!(location: web_mercator.point(1, 2))
      bbox = RGeo::Cartesian::BoundingBox.create_from_points(web_mercator.point(-1, -1), web_mercator.point(4, 4))

      expect(place.find_by(places[:location].st_within(bbox))).to eq(record)
    end

    it "passes SRID 4326 arguments longitude first" do
      record = place.create!(coordinates: spherical.point(-72.1, 42.1))
      nearby = spherical.point(-72.099, 42.099)

      expect(place.find_by(places[:coordinates].st_distance_sphere(nearby).lt(500))).to eq(record)
      expect(place.find_by(places[:coordinates].st_distance_sphere("SRID=4326;POINT(-72.099 42.099)").lt(500)))
        .to eq(record)
    end

    it "rejects raw strings outside spatial functions, as Arel does" do
      function = Arel::Nodes::NamedFunction.new("ST_IsValid", ["POINT(1 2)"])

      expect { place.where(function).to_a }.to raise_error(Arel::Visitors::UnsupportedVisitError)
    end

    it "reads WKT wrapped in Arel.spatial anywhere in Arel" do
      record = place.create!(location: web_mercator.point(1, 2))
      function = Arel::Nodes::NamedFunction.new("ST_Equals", [places[:location], Arel.spatial("SRID=3857;POINT(1 2)")])

      expect(place.find_by(function)).to eq(record)
    end
  end

  describe "#st_distance_sphere" do
    let!(:record) { place.create!(coordinates: spherical.point(-72.1, 42.1)) }

    it "measures the distance between two points on a sphere, in meters" do
      distance = place.pick(places[:coordinates].st_distance_sphere(spherical.point(-72.1, 42.2)))

      expect(distance).to be_within(1).of(11_119)
    end

    it "takes the sphere's radius" do
      distance = place.pick(places[:coordinates].st_distance_sphere(spherical.point(-72.1, 42.2), 1))

      # On a sphere of radius 1, the distance is the angle in radians.
      expect(distance).to be_within(1e-9).of(0.1 * Math::PI / 180)
    end

    it "chains from a spatial constant" do
      distance = Arel.spatial(spherical.point(-72.099, 42.099)).st_distance_sphere(places[:coordinates])

      expect(place.find_by(distance.lt(500))).to eq(record)
    end
  end

  it "quotes geometries in SQL conditions" do
    place.create!(coordinates: spherical.point(-72.1, 42.1))

    expect(place.where("ST_Distance_Sphere(coordinates, ?) < 500", spherical.point(-72.099, 42.099)).count).to eq(1)
  end
end
