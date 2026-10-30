## [Unreleased]

- Initial project setup: Active Record 7.2 through edge, trilogy and mysql2
- Run Active Record's own test suite with the gem loaded (`rake regression`)
- Spatial columns load as RGeo geometries on trilogy and mysql2
- Spatial columns report their geometric type, SRID, and geographic, Z and M
  settings; comments are returned without activerecord-mysql2rgeo-adapter's
  `mysql2rgeo:*` markers
