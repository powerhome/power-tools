# activerecord-mysql-rgeo

Spatial support for Active Record's built-in MySQL adapters, backed by
[RGeo](https://github.com/rgeo/rgeo).

Unlike [activerecord-mysql2rgeo-adapter](https://github.com/stadia/activerecord-mysql2rgeo-adapter),
this gem is not a separate database adapter. It extends the adapters that ship
with Rails, so your application keeps `adapter: trilogy` or `adapter: mysql2`
and gains spatial columns, migrations and queries on the same connection.

> **Status:** under development. The spatial features are being ported from
> activerecord-mysql2rgeo-adapter; this page lists what is available today.

## Requirements

- Ruby 3.3+
- Active Record 7.2, 8.0, 8.1 or edge
- MySQL 8.0 or 8.4 (MariaDB is not supported)
- One MySQL driver: [trilogy](https://github.com/trilogy-libraries/trilogy) or
  [mysql2](https://github.com/brianmario/mysql2). This gem depends on neither;
  keep the one your application already uses.

## Installation

```ruby
# Gemfile
gem "activerecord-mysql-rgeo"
gem "trilogy" # or "mysql2"
```

## Usage

### Reading spatial columns

Columns of MySQL's spatial types (`GEOMETRY`, `POINT`, `LINESTRING`, `POLYGON`,
`MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON` and `GEOMETRYCOLLECTION`) load
as RGeo geometries. Each value keeps the SRID it was stored with, and is built
by the factory `RGeo::ActiveRecord::SpatialFactoryStore` picks for the column:

```ruby
place = Place.find(1)
place.location       # => #<RGeo::Geos::CAPIPointImpl "POINT (-122.0 47.0)">
place.location.srid  # => 4326
```

SRID 4326 values are read longitude first, the order MySQL stores them in.

### Spatial column details

Spatial columns are `ActiveRecord::MysqlRgeo::SpatialColumn`s. Besides the
usual column API, they report the column's geometric type, its SRID (from the
column's `SRID` attribute, 0 when it has none) and whether it is geographic or
has Z or M coordinates:

```ruby
column = Place.columns_hash["location"]
column.sql_type        # => "geometry(Point,3857)"
column.geometric_type  # => RGeo::Feature::Point
column.srid            # => 3857
column.geographic?     # => false
column.limit           # => { type: "st_point", srid: 3857 }
```

MySQL has no column attribute for "geographic", Z or M, so these are kept as
markers in the column comment (`mysql2rgeo:geographic`, `mysql2rgeo:has_z`,
`mysql2rgeo:has_m`), the format activerecord-mysql2rgeo-adapter writes.
`column.comment` returns the comment without them. Assigning WKT to an
attribute uses the column's SRID, and geographic columns use a geographic
factory.

Other columns are built exactly as Rails builds them.

### Writing spatial values

Assign an RGeo geometry, or WKT, EWKT, WKB or EWKB, and save:

```ruby
place.location = "POINT(-122 47)"
place.location = RGeo::Geographic.spherical_factory(srid: 4326).point(-122, 47)
place.save!
Place.where(location: place.location)
```

Values are written as `ST_GeomFromText(wkt, srid)`, with longitude first for
SRID 4326. A column with SRID 0 takes geometries of any SRID and stores them
with SRID 0. Text that is not a geometry is saved as `NULL`; any other value
that is not a geometry raises `ArgumentError`.

### Spatial attribute types

The attribute API knows `:st_point`, `:st_polygon`, `:line_string`,
`:multi_point`, `:multi_line_string` and `:multi_polygon`, with the `srid:`,
`geographic:`, `has_z:` and `has_m:` options. Use them for virtual attributes
or for spatial columns selected under another name:

```ruby
class Place < ApplicationRecord
  attribute :center, :st_point, srid: 3857
end

Place.select("ST_Centroid(area) AS center").first.center
```

They are registered for the `trilogy` and `mysql2` adapters only.

## Migrating from activerecord-mysql2rgeo-adapter

> This guide grows as features are ported. It lists every difference found so
> far.

- **Non-spatial columns are plain `MySQL::Column`s.** The upstream gem built a
  `SpatialColumn` for every column, so `column.spatial?` and `column.srid`
  answered for any column. Check `column.type == :geometry` instead.
- **`GEOMETRYCOLLECTION` columns are spatial.** MySQL 8 reports them as
  `geomcollection`, which the upstream gem didn't recognise, so their values
  loaded as binary strings. They now load as RGeo geometry collections.
- **Comments of columns with spatial defaults no longer show stray hex.** The
  upstream gem left the hex of the default's marker in `column.comment`.
- **Writing a value that is not a geometry raises `ArgumentError`.** The
  upstream gem raised a `RuntimeError` ("maybe should raise").
- **Spatial attribute types are registered per adapter.** The upstream gem
  registered `:st_point` and the others for every adapter; this gem registers
  them for `trilogy` and `mysql2`, so they don't clash with another spatial
  adapter, such as PostGIS, in the same application.

## Development

The specs need a MySQL server. By default they connect to `root:root@127.0.0.1:3306`,
which matches the MySQL server preinstalled on GitHub's Ubuntu runners. Override
it with `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD` and
`MYSQL_DATABASE`. For example, with Docker:

```sh
docker run -d --name activerecord-mysql-rgeo-mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0
MYSQL_PORT=3307 bundle exec rake
```

`bundle exec rake` runs the whole build:

- `rake spec`: the gem's own specs, once per driver (`spec:trilogy`, `spec:mysql2`).
- `rake regression`: Active Record's own test suite, once per driver
  (`regression:trilogy`, `regression:mysql2`), with this gem loaded. It shows
  the gem leaves non-spatial behaviour exactly as Rails ships it. The tests are
  checked out from the Rails repository into `tmp/rails/` at the tag matching
  the bundled Active Record. Some of those tests set legacy time zone names
  such as `US/Eastern`; on Debian and Ubuntu, install `tzdata-legacy`.
- RuboCop.

`regression/excludes.yml` lists the Active Record tests that are skipped, with
the reason for each. It holds two kinds of tests: tests that also fail without
this gem, and tests that check how plain Rails treats spatial columns, which
this gem changes on purpose. Run the suite with `REGRESSION_BASELINE=1` to see
which tests fail without the gem:

```sh
REGRESSION_BASELINE=1 MYSQL_PORT=3307 bundle exec rake regression:trilogy
```

Each supported Active Record version has an [Appraisal](https://github.com/thoughtbot/appraisal)
gemfile under `gemfiles/`. To run the build against one of them:

```sh
bundle exec appraisal rails-7-2 rake
```

## License

BSD-3-Clause. Portions are derived from activerecord-mysql2rgeo-adapter; see
[LICENSE.txt](../LICENSE.txt).
