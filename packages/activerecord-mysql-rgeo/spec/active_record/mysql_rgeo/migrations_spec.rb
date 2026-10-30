# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Spatial migrations" do
  let(:place) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "places"

      def self.name = "Place"
    end
  end

  after do
    connection.drop_table(:places, if_exists: true)
  end

  def connection
    ActiveRecord::Base.lease_connection
  end

  def column(name)
    connection.columns(:places).find { |c| c.name == name.to_s }
  end

  # How MySQL itself describes the column, bypassing this gem.
  def information_schema(name)
    connection.select_one(<<~SQL.squish)
      SELECT column_type, srs_id, is_nullable, column_comment FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'places' AND column_name = #{connection.quote(name.to_s)}
    SQL
  end

  describe "column helpers" do
    {
      geometry: ["geometry", RGeo::Feature::Geometry],
      point: ["point", RGeo::Feature::Point],
      st_point: ["point", RGeo::Feature::Point],
      polygon: ["polygon", RGeo::Feature::Polygon],
      st_polygon: ["polygon", RGeo::Feature::Polygon],
      line_string: ["linestring", RGeo::Feature::LineString],
      linestring: ["linestring", RGeo::Feature::LineString],
      multi_point: ["multipoint", RGeo::Feature::MultiPoint],
      multi_line_string: ["multilinestring", RGeo::Feature::MultiLineString],
      multi_polygon: ["multipolygon", RGeo::Feature::MultiPolygon],
      geometry_collection: ["geomcollection", RGeo::Feature::GeometryCollection],
    }.each do |helper, (mysql_type, geometric_type)|
      it "creates a #{mysql_type} column with t.#{helper}" do
        connection.create_table(:places) { |t| t.public_send(helper, :shape) }

        expect(information_schema(:shape)).to include("COLUMN_TYPE" => mysql_type)
        expect(column(:shape)).to have_attributes(geometric_type: geometric_type, srid: 0, geographic?: false)
      end

      it "creates a #{mysql_type} column with t.column and :#{helper}" do
        connection.create_table(:places) { |t| t.column :shape, helper }

        expect(information_schema(:shape)).to include("COLUMN_TYPE" => mysql_type)
      end
    end

    it "creates a geographic geometry column with t.geography" do
      connection.create_table(:places) { |t| t.geography :shape }

      expect(column(:shape)).to have_attributes(geometric_type: RGeo::Feature::Geometry, geographic?: true, srid: 4326)
    end

    it "creates a geographic geometry column with t.column and :geography" do
      connection.create_table(:places) { |t| t.column :shape, :geography }

      expect(information_schema(:shape)).to include("COLUMN_TYPE" => "geometry")
      expect(column(:shape)).to have_attributes(geographic?: true, srid: 4326)
    end

    it "creates the type given to t.spatial" do
      connection.create_table(:places) { |t| t.spatial :shape, type: :st_point, srid: 3857 }

      expect(column(:shape)).to have_attributes(geometric_type: RGeo::Feature::Point, srid: 3857)
    end

    it "requires a type for t.spatial" do
      expect { connection.create_table(:places) { |t| t.spatial :shape } }
        .to raise_error(ArgumentError, /t.spatial :shape, type: :st_point/)
    end

    it "creates several columns at once" do
      connection.create_table(:places) { |t| t.st_point :origin, :destination, srid: 3857 }

      expect([column(:origin).srid, column(:destination).srid]).to eq([3857, 3857])
    end
  end

  describe "column options" do
    it "sets the SRID attribute" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 3857 }

      expect(information_schema(:location)).to include("SRS_ID" => 3857)
      expect(column(:location).srid).to eq(3857)
    end

    it "sets SRID 0 when no SRID is given, as activerecord-mysql2rgeo-adapter does" do
      connection.create_table(:places) { |t| t.st_point :location }

      expect(information_schema(:location)).to include("SRS_ID" => 0)
    end

    it "marks geographic columns in the comment and defaults them to SRID 4326" do
      connection.create_table(:places) { |t| t.st_point :location, geographic: true, comment: "Where it is" }

      expect(information_schema(:location)).to include(
        "SRS_ID" => 4326, "COLUMN_COMMENT" => "Where it is mysql2rgeo:geographic"
      )
      expect(column(:location)).to have_attributes(geographic?: true, comment: "Where it is")
    end

    it "marks Z and M in the comment" do
      connection.create_table(:places) { |t| t.st_polygon :area, has_z: true, has_m: true, srid: 3857 }

      expect(information_schema(:area)).to include("COLUMN_COMMENT" => "mysql2rgeo:has_m mysql2rgeo:has_z")
      expect(column(:area).limit).to eq(type: "st_polygon", srid: 3857, has_z: true, has_m: true)
    end

    it "takes the options from a limit hash, as schema.rb writes them" do
      connection.create_table(:places) do |t|
        t.geometry :location, limit: { srid: 4326, type: "st_point", geographic: true }
      end

      expect(column(:location)).to have_attributes(
        geometric_type: RGeo::Feature::Point, srid: 4326, geographic?: true
      )
    end

    it "creates NOT NULL columns" do
      connection.create_table(:places) { |t| t.st_point :location, null: false }

      expect(information_schema(:location)).to include("IS_NULLABLE" => "NO")
    end

    it "still rejects spatial options on other columns" do
      expect { connection.create_table(:places) { |t| t.string :name, srid: 4326 } }
        .to raise_error(ArgumentError, /Unknown key: :srid/)
    end

    it "leaves non-spatial columns alone" do
      connection.create_table(:places) { |t| t.string :name, limit: 123, comment: "Shown on the map" }

      expect(column(:name)).to have_attributes(limit: 123, comment: "Shown on the map")
    end
  end

  describe "defaults" do
    it "stores the default in the comment, as activerecord-mysql2rgeo-adapter does" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 3875, default: "POINT(0.0 0.0)" }

      expect(information_schema(:location)["COLUMN_COMMENT"])
        .to eq("mysql2rgeo:default:010100000000000000000000000000000000000000")
      expect(column(:location)).to have_attributes(default: "010100000000000000000000000000000000000000", comment: nil)
    end

    it "stores geographic defaults with their SRID" do
      connection.create_table(:places) do |t|
        t.geography :location, limit: { srid: 4326, type: "st_point", geographic: true }, default: "POINT(0.0 0.0)"
      end

      expect(column(:location).default).to eq("0101000020E610000000000000000000000000000000000000")
    end

    it "gives new models the default" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 0, default: "POINT(1.0 2.0)" }

      expect(place.new.location).to have_attributes(x: 1.0, y: 2.0, srid: 0)
    end

    it "saves the default when partial inserts are off, as in apps on Rails 7.0 defaults" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 0, default: "POINT(1.0 2.0)" }
      place.partial_inserts = false

      expect(place.create!.reload.location).to have_attributes(x: 1.0, y: 2.0)
    end
  end

  describe "changing tables" do
    before do
      connection.create_table(:places) { |t| t.st_point :location, srid: 3857, geographic: false, comment: "Where" }
    end

    it "adds spatial columns" do
      connection.change_table(:places) do |t|
        t.st_point :coordinates, srid: 4326, geographic: true
        t.string :name
      end

      expect(column(:coordinates)).to have_attributes(srid: 4326, geographic?: true)
      expect(column(:name).type).to eq(:string)
    end

    it "removes spatial columns" do
      connection.change_table(:places) { |t| t.remove :location }

      expect(column(:location)).to be_nil
    end

    it "changes nullability and keeps the SRID and comment" do
      connection.change_column_null(:places, :location, false)

      expect(information_schema(:location)).to include("IS_NULLABLE" => "NO", "SRS_ID" => 3857)
      expect(column(:location)).to have_attributes(geometric_type: RGeo::Feature::Point, comment: "Where")
    end

    it "changes the comment and keeps the markers" do
      connection.change_table(:places) { |t| t.st_point :coordinates, geographic: true }
      connection.change_column_comment(:places, :coordinates, "Measured")

      expect(information_schema(:coordinates)).to include("COLUMN_COMMENT" => "Measured mysql2rgeo:geographic")
    end
  end

  describe "spatial indexes" do
    def index_type(name)
      connection.select_value(<<~SQL.squish)
        SELECT index_type FROM information_schema.statistics
        WHERE table_schema = DATABASE() AND table_name = 'places' AND index_name = #{connection.quote(name)}
      SQL
    end

    it "creates a spatial index for using: :gist in create_table" do
      connection.create_table(:places) do |t|
        t.st_point :location, srid: 3857, null: false
        t.index :location, using: :gist, name: "index_places_on_location"
      end

      expect(index_type("index_places_on_location")).to eq("SPATIAL")
    end

    it "adds a spatial index, making the column NOT NULL as MySQL requires" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 3857, comment: "Where" }
      connection.add_index :places, :location, using: :gist

      expect(index_type("index_places_on_location")).to eq("SPATIAL")
      expect(information_schema(:location)).to include("IS_NULLABLE" => "NO", "SRS_ID" => 3857)
      expect(column(:location).comment).to eq("Where")
    end

    it "adds a spatial index in change_table" do
      connection.create_table(:places) { |t| t.st_point :location, srid: 3857 }
      connection.change_table(:places) { |t| t.index :location, using: :gist }

      expect(index_type("index_places_on_location")).to eq("SPATIAL")
    end
  end

  it "creates generated spatial columns" do
    connection.create_table(:places) do |t|
      t.st_point :location, srid: 3857
      t.virtual :area, type: :st_polygon, as: "ST_Buffer(location, 10)", stored: true
    end

    expect(column(:area)).to have_attributes(type: :geometry, virtual?: true)
  end
end
