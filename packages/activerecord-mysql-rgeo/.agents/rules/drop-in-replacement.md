# Drop-in replacement for activerecord-mysql2rgeo-adapter

Applications must be able to swap `activerecord-mysql2rgeo-adapter` for this gem
by changing the Gemfile, without data migrations and with no or minimal code
changes. Upstream reference: https://github.com/stadia/activerecord-mysql2rgeo-adapter.

Behaviour matches the latest upstream release (9.1.0). Apps may come from any
upstream line, so the migration guide is organised by the upstream version
range the reader is on (for example 7.x, 8.x, 9.x). For each range it lists
what changes for them, including upstream changes they never upgraded to
(9.0.0's raw-String Arel change, the `mysql2rgeo:*` comment markers and
`SRID` column attribute added after 7.2.0). Every such difference has a spec.

## Must stay identical

- **Data written to the database.** Column comment markers
  (`mysql2rgeo:geographic`, `mysql2rgeo:has_z`, `mysql2rgeo:has_m`,
  `mysql2rgeo:array`, `mysql2rgeo:default:<hex>`), the SRID column attribute,
  spatial index DDL, and how geometries are encoded (WKT/WKB, SRID 4326 axis
  order). Existing databases must read back exactly as before, and new writes
  must be readable by the upstream gem.
- **`adapter: mysql2rgeo` keeps working.** It is registered as an alias of
  Rails' `Mysql2Adapter`. Document `trilogy` as the recommended replacement.
- **Migration DSL:** `t.geometry`, `t.geography`, `t.st_point`, `t.point`,
  `t.line_string`, `t.polygon`, `t.multi_*`, `t.geometry_collection`,
  `t.spatial type: ...`, the `srid:`, `geographic:`, `has_z:`, `has_m:`
  options, and `add_index ..., using: :gist`.
- **`schema.rb` output.** A schema dumped with the upstream gem must load with
  this one, and dumping again must produce the same file.
- **Ruby API:** `ActiveRecord::Type::Spatial`, RGeo values on model attributes,
  WKT/WKB string assignment, Arel spatial nodes (`st_distance_sphere`, ...),
  `RGeo::ActiveRecord::SpatialFactoryStore` configuration.
- **Public constants.** Keep the upstream names
  (`ActiveRecord::ConnectionAdapters::Mysql2Rgeo::*`, `Arel::Visitors::Mysql2Rgeo`,
  `ActiveRecord::ConnectionAdapters::Mysql2Rgeo::OID::Spatial`) available as
  aliases of the new ones, and mark them for deprecation rather than removing
  them.

## Allowed differences

Only differences that come from no longer being a separate adapter, such as
`connection.adapter_name` returning `"Trilogy"` / `"Mysql2"` instead of
`"Mysql2Rgeo"`. Each one must be:

- listed in the README's "Migrating from activerecord-mysql2rgeo-adapter"
  section, with what to do about it;
- covered by a spec that pins the new behaviour;
- noted in the CHANGELOG.

## How to verify

- When porting a feature, port the upstream tests for it first (see
  `testing.md`).
- Keep a compatibility spec that loads a fixture `schema.rb` and column
  comments produced by the upstream gem and checks they round-trip.
