# frozen_string_literal: true

require "open3"
require "spec_helper"

RSpec.describe "Reading spatial values" do
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
          name varchar(255),
          shape GEOMETRY,
          location POINT,
          path LINESTRING,
          area POLYGON,
          spots MULTIPOINT,
          paths MULTILINESTRING,
          areas MULTIPOLYGON,
          collection GEOMETRYCOLLECTION
        )
      SQL
    end
  end

  after do
    ActiveRecord::Base.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
  end

  def insert_place(**columns)
    ActiveRecord::Base.with_connection do |connection|
      connection.execute(<<~SQL.squish)
        INSERT INTO places (#{columns.keys.join(', ')}) VALUES (#{columns.values.join(', ')})
      SQL
    end
    place.last
  end

  it "loads each spatial column type as the matching RGeo geometry" do
    record = insert_place(
      shape: "ST_GeomFromText('POINT(1 2)')",
      location: "ST_GeomFromText('POINT(1 2)')",
      path: "ST_GeomFromText('LINESTRING(0 0, 1 1)')",
      area: "ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 0 0))')",
      spots: "ST_GeomFromText('MULTIPOINT((0 0), (1 1))')",
      paths: "ST_GeomFromText('MULTILINESTRING((0 0, 1 1), (2 2, 3 3))')",
      areas: "ST_GeomFromText('MULTIPOLYGON(((0 0, 0 1, 1 1, 0 0)))')",
      collection: "ST_GeomFromText('GEOMETRYCOLLECTION(POINT(1 2))')"
    )

    expect(record).to have_attributes(
      shape: RGeo::Feature::Point,
      location: RGeo::Feature::Point,
      path: RGeo::Feature::LineString,
      area: RGeo::Feature::Polygon,
      spots: RGeo::Feature::MultiPoint,
      paths: RGeo::Feature::MultiLineString,
      areas: RGeo::Feature::MultiPolygon,
      collection: RGeo::Feature::GeometryCollection
    )
  end

  it "keeps the coordinates" do
    record = insert_place(location: "ST_GeomFromText('POINT(1.5 -2.25)')")

    expect(record.location).to have_attributes(x: 1.5, y: -2.25)
  end

  it "keeps the SRID the value was stored with" do
    record = insert_place(shape: "ST_GeomFromText('POINT(1 2)', 3857)")

    expect(record.shape.srid).to eq(3857)
  end

  it "reads SRID 4326 values longitude first" do
    record = insert_place(shape: "ST_GeomFromText('POINT(-122 47)', 4326, 'axis-order=long-lat')")

    expect(record.shape).to have_attributes(x: -122.0, y: 47.0, srid: 4326)
  end

  it "returns nil for NULL" do
    record = insert_place(name: "'Nowhere'")

    expect(record).to have_attributes(name: "Nowhere", location: nil)
  end

  describe "load order" do
    adapter_class = { "trilogy" => "TrilogyAdapter", "mysql2" => "Mysql2Adapter" }.fetch(TestDatabase.adapter)
    load_adapter = <<~RUBY
      require "active_record"
      require "active_record/connection_adapters/#{TestDatabase.adapter}_adapter"
    RUBY
    print_point_type = <<~RUBY
      print ActiveRecord::ConnectionAdapters::#{adapter_class}::TYPE_MAP.lookup("point").class
    RUBY

    def run_ruby(script)
      output, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-rbundler/setup", "-e", script)
      expect(status).to be_success, output
      output
    end

    it "maps spatial columns when the gem is required before the driver adapter loads" do
      output = run_ruby(%(require "activerecord-mysql-rgeo"\n#{load_adapter}#{print_point_type}))

      expect(output).to eq("ActiveRecord::MysqlRgeo::Type::Spatial")
    end

    it "maps spatial columns when the gem is required after the driver adapter loads" do
      output = run_ruby(%(#{load_adapter}require "activerecord-mysql-rgeo"\n#{print_point_type}))

      expect(output).to eq("ActiveRecord::MysqlRgeo::Type::Spatial")
    end

    it "maps spatial columns for MySQL adapter classes defined afterwards" do
      output = run_ruby(<<~RUBY)
        require "activerecord-mysql-rgeo"
        #{load_adapter}
        class CustomAdapter < ActiveRecord::ConnectionAdapters::#{adapter_class}
          TYPE_MAP = ActiveRecord::Type::TypeMap.new.tap { |m| initialize_type_map(m) }
        end
        print CustomAdapter::TYPE_MAP.lookup("point").class
      RUBY

      expect(output).to eq("ActiveRecord::MysqlRgeo::Type::Spatial")
    end
  end
end
