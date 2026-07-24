## [Unreleased]

## [0.5.0] - 2026-05-12

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Upgrade Rails to 8.1.3 for Nitro and Runway compatability
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Update Rails version to 7.2.3.1 for Active Storage CVE [#402](https://github.com/powerhome/power-tools/pull/402)

### Dependencies and platform support

- Update rainbow to v3.x [#372](https://github.com/powerhome/power-tools/pull/372)
- Update yard to 0.9.38 to address [Cross-site Scripting vulnerability](https://github.com/powerhome/power-tools/security/dependabot/544) [#394](https://github.com/powerhome/power-tools/pull/394)
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)

---

- Remove more Rails 6.0 config handling
- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Lock activesupport requirement to ~> 7.0.8
- Setup test environment and add simple specs
- Fix issue reading database config to support Rails 6.0
- Add more specs, including actual run of a dump for default sanitization

## [0.5.1] - 2026-07-16

### Breaking changes

- Replace `DataTaster.config(source_client:, working_client:, include_insert:, ...)` with `DataTaster.setup(source:, output:, months:, list:)`
- Configure exports with a `MysqlSource` and an output adapter (`DatabaseOutput` or `FileOutput`) instead of raw MySQL clients
- Remove `include_insert` — export behavior is determined by the output adapter
- Remove `DataTaster::Sample` and `DataTaster.safe_execute` — export logic now lives in output adapters

### Added

- **SQL file export**: `FileOutput` writes sanitized INSERT statements to a SQL file without mutating a target database
- **Adapter architecture**: `MysqlSource`, `Output`, `DatabaseOutput`, and `FileOutput` separate source reads from export destination
- **Inline sanitization on export**: Both file and database exports apply sanitization rules while building INSERT statements via `SanitizerExporter`, `ExportContext`, and `SqlLiteral`
- **`DataTaster.reset!`**: Clears configuration and confection between runs
- **`SqlLiteral`**: Formats Ruby values as MySQL literals with correct handling for JSON, binary/blob, temporal, and scalar types
- Expanded test coverage for adapters, SQL literals, and integration flows

### Changed

- Database export (`DatabaseOutput`) inserts sanitized rows directly and still runs post-export UPDATE sanitization
- File export only includes tables defined in confection keys
- Default `schema_migrations` confection entry is provided by `DatabaseOutput` only
- Move row-expression sanitization (`wash_values`) into `Detergent`

### Fixed

- Correctly treat JSON column values as quoted strings instead of binary hex literals

## [0.5.0] - 2026-07-08

- Published in the wrong order and produced errors. Use 0.5.1 instead.

## [0.4.3] - 2025-07-28

## [0.4.2] - 2025-02-27

- Lower nokogiri requirement to 1.14

## [0.4.1] - 2025-02-27

- Fix date flavor for newer rails versions

## [0.3.0] - 2024-04-25

- Add compatibility for encryption with newer versions of attr_encrypted

## [0.2.0] - 2023-12-24

- Rollout of basic features. See README for details.

## [0.1.0] - 2023-05-30

- Initial release
