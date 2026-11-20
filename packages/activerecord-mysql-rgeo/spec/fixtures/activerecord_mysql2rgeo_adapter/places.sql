-- SHOW CREATE TABLE output for the table spec/support/upstream_places.rb defines,
-- created by activerecord-mysql2rgeo-adapter 9.1.0 (Active Record 8.1, MySQL 8.0).
CREATE TABLE `places` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL COMMENT 'Shown on the map',
  `shape` geometry /*!80003 SRID 0 */ DEFAULT NULL,
  `location` point NOT NULL /*!80003 SRID 3857 */ COMMENT 'Where it is',
  `coordinates` point /*!80003 SRID 4326 */ DEFAULT NULL COMMENT 'mysql2rgeo:geographic',
  `area` polygon /*!80003 SRID 3857 */ DEFAULT NULL COMMENT 'mysql2rgeo:has_m',
  `zones` multipolygon /*!80003 SRID 0 */ DEFAULT NULL,
  `path` linestring /*!80003 SRID 3857 */ DEFAULT NULL,
  `stops` multipoint /*!80003 SRID 0 */ DEFAULT NULL,
  `routes` multilinestring /*!80003 SRID 0 */ DEFAULT NULL,
  `origin` point /*!80003 SRID 3857 */ DEFAULT NULL COMMENT 'mysql2rgeo:default:0101000000000000000000F03F0000000000000040',
  PRIMARY KEY (`id`),
  SPATIAL KEY `index_places_on_location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
