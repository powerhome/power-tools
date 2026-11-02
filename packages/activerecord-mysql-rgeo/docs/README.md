# activerecord-mysql-rgeo 🌍

Spatial columns for Rails' own MySQL adapters, powered by [RGeo](https://github.com/rgeo/rgeo).

[activerecord-mysql2rgeo-adapter](https://github.com/stadia/activerecord-mysql2rgeo-adapter)
is a whole database adapter: you switch to `adapter: mysql2rgeo` and you're
tied to the mysql2 driver. This gem isn't an adapter. It teaches the adapters
Rails already ships, `trilogy` and `mysql2`, to speak spatial. Keep your
adapter, keep your connection, get points and polygons.

## Requirements

- Ruby 3.3+
- Active Record 7.2, 8.0, 8.1 or edge
- MySQL 8.0 or 8.4 (not MariaDB)
- [trilogy](https://github.com/trilogy-libraries/trilogy) or
  [mysql2](https://github.com/brianmario/mysql2). Bring your own; this gem
  depends on neither.

## Installation

```ruby
# Gemfile
gem "activerecord-mysql-rgeo"
gem "trilogy" # or "mysql2"
```

That's it. `database.yml` stays `adapter: trilogy` (or `mysql2`).

## Usage

### Reading

Spatial columns (`GEOMETRY`, `POINT`, `LINESTRING`, `POLYGON`, `MULTIPOINT`,
`MULTILINESTRING`, `MULTIPOLYGON`, `GEOMETRYCOLLECTION`) load as RGeo
geometries, built by `RGeo::ActiveRecord::SpatialFactoryStore` (geographic
columns get a geographic factory):

```ruby
place = Place.find(1)
place.location       # => #<RGeo::Geos::CAPIPointImpl "POINT (-122.0 47.0)">
place.location.srid  # => 4326
```

Spatial columns know a few more things than regular ones:

```ruby
column = Place.columns_hash["location"]
column.spatial?        # => true (false on every other column)
column.sql_type        # => "geometry(Point,3857)"
column.geometric_type  # => RGeo::Feature::Point
column.srid            # => 3857 (0 without an SRID attribute)
column.geographic?     # => false
column.has_z?          # => false
column.has_m?          # => false
column.limit           # => { type: "st_point", srid: 3857 }
```

### Writing

Assign an RGeo geometry, WKT, EWKT, WKB or EWKB:

```ruby
place.location = "POINT(-122 47)"
place.location = RGeo::Geographic.spherical_factory(srid: 4326).point(-122, 47)
place.save!
```

- WKT without an SRID takes the column's.
- SRID 4326 is longitude first, like WKT.
- SRID 0 columns take geometries of any SRID and store them as SRID 0.
- Text that isn't a geometry saves `NULL`. Anything else that isn't a geometry
  raises `ArgumentError`.

### Queries

Exact matches:

```ruby
Place.where(location: factory.point(-122, 47))
Place.where(location: "SRID=3857;POINT(-122 47)")
```

Spatial functions, from [rgeo-activerecord](https://github.com/rgeo/rgeo-activerecord)
(`st_distance`, `st_contains`, `st_within`, `st_intersects`, `st_length`, ...)
plus `st_distance_sphere` from this gem:

```ruby
places = Place.arel_table

Place.where(places[:area].st_contains(factory.point(-122, 47)))
Place.where(places[:location].st_distance("SRID=3857;POINT(-122 47)").lt(100))
Place.where(places[:coordinates].st_distance_sphere(point).lt(500))      # meters
Place.where(places[:coordinates].st_distance_sphere(point, 1).lt(0.01))  # custom radius
Place.where(Arel.spatial(point).st_distance_sphere(places[:coordinates]).lt(500))
```

Arguments can be geometries, bounding boxes, WKT, EWKT, attributes or other
spatial functions. Geometries work in SQL fragments too:

```ruby
Place.where("ST_Distance_Sphere(coordinates, ?) < 500", point)
```

Strings are WKT only as spatial function arguments. Anywhere else in Arel,
wrap them: `Arel.spatial("POINT(1 2)")`.

### Attribute types

`:st_point`, `:st_polygon`, `:line_string`, `:multi_point`,
`:multi_line_string` and `:multi_polygon`, with `srid:`, `geographic:`,
`has_z:` and `has_m:`. Handy for virtual attributes and computed columns:

```ruby
class Place < ApplicationRecord
  attribute :center, :st_point, srid: 3857
end

Place.select("ST_Centroid(area) AS center").first.center
```

Registered for `trilogy` and `mysql2` only.

### Migrations

```ruby
create_table :places do |t|
  t.st_point :location, srid: 3857, null: false
  t.geography :area                       # GEOMETRY, SRID 4326, geographic
  t.multi_polygon :zones, has_z: true
  t.spatial :shape, type: :st_polygon
  t.index :location, using: :gist         # SPATIAL INDEX
end

add_column :places, :entrance, :st_point, srid: 3857
add_index :places, :entrance, using: :gist
```

Helpers: `geometry`, `geography`, `point` / `st_point`, `polygon` /
`st_polygon`, `line_string`, `multi_point`, `multi_line_string`,
`multi_polygon`, `geometry_collection` and `spatial` (with `type:`). They work
with `t.column` and `add_column` too.

| Option | Does |
|---|---|
| `srid:` | Sets the column's `SRID`. Default: 0, or 4326 for geographic columns. |
| `geographic:`, `has_z:`, `has_m:` | Stored as markers in the column comment (`mysql2rgeo:geographic`, ...). `column.comment` hides them. |
| `default:` | WKT or a geometry. Stored in the column comment, applied to new records. Saved only with partial inserts off (the default since Rails 7.0). |
| `limit:` | The options above as a hash, the way `schema.rb` writes them. |

- `using: :gist` makes a `SPATIAL INDEX`. MySQL needs `NOT NULL` for those, so
  `add_index` sets it.
- `change_column`, `change_column_null` and `change_column_comment` keep the
  column's spatial type, SRID and markers.

### schema.rb

```ruby
create_table "places", force: :cascade do |t|
  t.geometry "location", limit: {type: "st_point", srid: 3857}, null: false
  t.geometry "coordinates", limit: {type: "st_point", srid: 4326, geographic: true}
  t.geometry "origin", limit: {type: "st_point", srid: 3857}, default: "POINT (1.0 2.0)"
  t.index ["location"], name: "index_places_on_location", using: :gist, type: :spatial
end
```

Same format as activerecord-mysql2rgeo-adapter. The schema cache keeps spatial
columns too, in YAML, Marshal and (Active Record 8.2) JSON.

### Deprecations

Warnings go through `ActiveRecord::MysqlRgeo.deprecator`, which Rails apps
register in `Rails.application.deprecators`.

## Migrating from activerecord-mysql2rgeo-adapter

Your data stays put: same columns, same comment markers, same `schema.rb`.

1. Gemfile: swap `activerecord-mysql2rgeo-adapter` for `activerecord-mysql-rgeo`,
   and add `trilogy` (recommended) or `mysql2`.
2. `database.yml` and `DATABASE_URL`: change `adapter: mysql2rgeo` to
   `trilogy` or `mysql2`.
3. Run `bin/rails db:schema:dump` and commit the diff.
4. Have a `db/schema_cache.yml`? Run `bin/rails db:schema:cache:dump`, or
   delete it. The old one fails to load with "undefined class/module
   ActiveRecord::ConnectionAdapters::Mysql2Rgeo::".

Then check the list for your version. Loading both gems raises
`ActiveRecord::MysqlRgeo::ConflictingGemError`.

### Every version

- `connection.adapter_name` is `"Trilogy"` or `"Mysql2"`, not `"Mysql2Rgeo"`.
- Non-spatial columns are plain `ActiveRecord::ConnectionAdapters::MySQL::Column`s.
  They answer `spatial?` (`false`), but not `srid`, `geographic?`, `has_z?`,
  `has_m?` or `geometric_type`.
- The spatial type is `ActiveRecord::MysqlRgeo::Type::Spatial`.
  `ActiveRecord::Type::Spatial` and
  `ActiveRecord::ConnectionAdapters::Mysql2Rgeo::OID::Spatial` still work, with
  a deprecation warning.
- Gone: `ActiveRecord::ConnectionAdapters::Mysql2RgeoAdapter` (check
  `adapter_name`, or `is_a?(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter)`),
  `Arel::Visitors::Mysql2Rgeo` and the rest of
  `ActiveRecord::ConnectionAdapters::Mysql2Rgeo`.
- Writing something that isn't a geometry raises `ArgumentError`, not
  `RuntimeError`.
- Spatial attribute types (`:st_point`, ...) exist for `trilogy` and `mysql2`
  only, so they don't clash with PostGIS in the same app.
- `connection.indexes` reports spatial indexes as Rails does: `type: :spatial`,
  `using: nil`. `schema.rb` still writes `using: :gist`.

Fixed along the way:

- `GEOMETRYCOLLECTION` columns load as geometries, not binary strings.
- `column.comment` no longer shows the hex of a spatial default.
- `t.column :name, :geography` makes a geographic `GEOMETRY` column, like
  `t.geography`.
- `change_column`, `change_column_null` and `change_column_comment` work on
  spatial columns without repeating the spatial options.
- `schema.rb` writes spatial defaults as WKT. The old gem wrote them as
  `#<RGeo::...>`, which broke the file. Step 3 fixes it.
- `st_distance_sphere(point, radius)` works. The old gem raised
  `Arel::Visitors::UnsupportedVisitError`.

### Coming from 8.x or earlier

- Strings in Arel nodes aren't WKT any more (the old gem changed this in 9.0):
  `Arel::Nodes::NamedFunction.new("ST_IsValid", ["POINT(1 2)"])` raises
  `Arel::Visitors::UnsupportedVisitError`. Pass a geometry, or
  `Arel.spatial("POINT(1 2)")`.

### Coming from 7.2 or earlier

Everything in the 8.x list, plus:

- **SRID 4326 values were stored swapped**, latitude first, and longitudes
  beyond ±90 raised errors. This gem stores them longitude first. Old rows read
  back exactly as before, swapped. Fix them once, when you switch:

  ```sql
  UPDATE places SET coordinates = ST_SwapXY(coordinates) WHERE coordinates IS NOT NULL;
  ```

- `geographic:`, `has_z:`, `has_m:` and spatial `default:` now stick: they're
  stored in the column comment. Columns you already have read the same as
  before (not geographic, no Z or M). To mark one:

  ```ruby
  change_column :places, :coordinates, :st_point, srid: 4326, geographic: true
  ```

- `geographic: true` gives SRID 4326 unless you pass `srid:`. It used to give 0.
- New columns always get an `SRID` attribute, `SRID 0` included, so MySQL
  rejects values with another SRID in them. That includes tables created by
  `db:schema:load`. Existing columns don't change.
- `add_index ..., using: :gist` works and makes a `SPATIAL INDEX`.
  `type: :spatial` still works too.
- The `schema.rb` diff from step 3 includes `type: "st_point"` (was `"point"`),
  `type: "st_polygon"` (was `"polygon"`) and `using: :gist` on spatial indexes.

## Development

The specs need MySQL. They connect to `root:root@127.0.0.1:3306` (what
GitHub's Ubuntu runners have) unless you set `MYSQL_HOST`, `MYSQL_PORT`,
`MYSQL_USER`, `MYSQL_PASSWORD` or `MYSQL_DATABASE`. With Docker:

```sh
docker run -d --name activerecord-mysql-rgeo-mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0
MYSQL_PORT=3307 bundle exec rake
```

`bundle exec rake` runs everything:

- `rake spec`: this gem's specs, on trilogy and on mysql2.
- `rake regression`: Active Record's own test suite with this gem loaded, on
  both drivers. It's checked out into `tmp/rails/` at the bundled Active
  Record's version. Some tests need legacy time zones; on Debian and Ubuntu,
  install `tzdata-legacy`.
- RuboCop.

`regression/excludes.yml` lists the skipped Active Record tests and why: either
they fail without this gem too, or they check how plain Rails treats spatial
columns, which this gem changes on purpose. See what fails without the gem:

```sh
REGRESSION_BASELINE=1 MYSQL_PORT=3307 bundle exec rake regression:trilogy
```

Run the build on one Active Record version with
[Appraisal](https://github.com/thoughtbot/appraisal):

```sh
bundle exec appraisal rails-7-2 rake
```

## License

BSD-3-Clause. Parts come from activerecord-mysql2rgeo-adapter; see
[LICENSE.txt](../LICENSE.txt).
