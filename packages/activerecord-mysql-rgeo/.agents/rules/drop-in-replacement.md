# Drop-in replacement for activerecord-mysql2rgeo-adapter

Apps must swap `activerecord-mysql2rgeo-adapter` (https://github.com/stadia/activerecord-mysql2rgeo-adapter) for this gem by changing only Gemfile and `database.yml`: no data migrations, no/minimal code changes.

Behaviour matches latest upstream (9.1.0). Apps may come from any upstream line, so the migration guide is organised by upstream version range (e.g. 7.x, 8.x, 9.x), each listing what changes for them, including upstream changes they never upgraded to (9.0.0's raw-String Arel change; `mysql2rgeo:*` comment markers and `SRID` column attribute added after 7.2.0). Every such difference has a spec.

## Must stay identical

- **Data written to the DB:** column comment markers (`mysql2rgeo:geographic`, `mysql2rgeo:has_z`, `mysql2rgeo:has_m`, `mysql2rgeo:array`, `mysql2rgeo:default:<hex>`), SRID column attribute, spatial index DDL, geometry encoding (WKT/WKB, SRID 4326 axis order). Existing DBs read back exactly as before; new writes readable by upstream.
- **Migration DSL:** `t.geometry`, `t.geography`, `t.st_point`, `t.point`, `t.line_string`, `t.polygon`, `t.multi_*`, `t.geometry_collection`, `t.spatial type: ...`; options `srid:`, `geographic:`, `has_z:`, `has_m:`; `add_index ..., using: :gist`.
- **`schema.rb`:** an upstream-dumped schema loads here, and re-dumping produces the same file.
- **Ruby API:** spatial type, RGeo values on model attributes, WKT/WKB string assignment, Arel spatial nodes (`st_distance_sphere`, ...), `RGeo::ActiveRecord::SpatialFactoryStore` config.
- **Stored/referenced constants:** keep an upstream constant only if data or plausible app code refers to it: `ActiveRecord::Type::Spatial` and `ActiveRecord::ConnectionAdapters::Mysql2Rgeo::OID::Spatial` stay as deprecated aliases. Internal (`:nodoc:`) upstream classes are not kept. Regenerable files naming upstream classes (e.g. schema cache) are regenerated (documented migration step).

## Allowed differences

Only those from no longer being a separate adapter, e.g. `connection.adapter_name` returns `"Trilogy"`/`"Mysql2"` not `"Mysql2Rgeo"`; `adapter: mysql2rgeo` becomes `adapter: trilogy` (recommended) or `mysql2`. No `mysql2rgeo` adapter exists: config changes fine, deep code changes not. Each difference must be:

- in README's "Migrating from activerecord-mysql2rgeo-adapter" with what to do;
- pinned by a spec;
- in the CHANGELOG.

## Verify

- Porting a feature: port its upstream tests first (see `testing.md`).
- Keep a compatibility spec loading an upstream-produced fixture `schema.rb` and column comments and checking they round-trip.
