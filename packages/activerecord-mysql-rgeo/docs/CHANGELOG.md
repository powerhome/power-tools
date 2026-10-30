## [Unreleased]

- Initial project setup: Active Record 7.2 through edge, trilogy and mysql2
- Run Active Record's own test suite with the gem loaded (`rake regression`)
- Spatial columns load as RGeo geometries on trilogy and mysql2
- Spatial columns report their geometric type, SRID, and geographic, Z and M
  settings; comments are returned without activerecord-mysql2rgeo-adapter's
  `mysql2rgeo:*` markers
- Save RGeo geometries, WKT, EWKT, WKB and EWKB to spatial columns, and query
  by them
- Spatial attribute types (`attribute :center, :st_point, srid: 3857`)
- Spatial migrations: column helpers (`t.st_point`, `t.geography`, ...), the
  `SRID` attribute, `geographic:`, `has_z:`, `has_m:` and `default:` kept in
  the column comment, and spatial indexes with `using: :gist`
