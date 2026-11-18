# frozen_string_literal: true

# A table with every kind of spatial column, created with the same migration
# that produced spec/fixtures/activerecord_mysql2rgeo_adapter/ with
# activerecord-mysql2rgeo-adapter 9.1.0. To record new fixtures, run this
# migration with that gem and save SHOW CREATE TABLE and the schema.rb dump.
module UpstreamPlaces
  FIXTURES = File.expand_path("../fixtures/activerecord_mysql2rgeo_adapter", __dir__)

  COLUMNS = proc do |t|
    t.string :name, comment: "Shown on the map"
    t.geometry :shape
    t.st_point :location, srid: 3857, null: false, comment: "Where it is"
    t.st_point :coordinates, geographic: true
    t.st_polygon :area, srid: 3857, has_m: true
    t.multi_polygon :zones, srid: 0
    t.line_string :path, srid: 3857
    t.multi_point :stops
    t.multi_line_string :routes
    t.st_point :origin, srid: 3857, default: "POINT(1.0 2.0)"
    t.index :location, using: :gist
  end

module_function

  def create_table(connection)
    connection.create_table(:places, force: true, &COLUMNS)
  end

  def create_table_sql
    File.read(File.join(FIXTURES, "places.sql")).lines.grep_v(/\A--/).join.strip
  end

  # The create_table block of the upstream schema.rb dump.
  def schema
    File.read(File.join(FIXTURES, "places_schema.txt")).lines.grep_v(/\A#/).join
  end
end
