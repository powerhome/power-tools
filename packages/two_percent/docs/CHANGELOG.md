## [Unreleased]

## [1.0.0] - 2026-05-20

- **Domain Events System**: TwoPercent now publishes domain events when SCIM resources change [#424](https://github.com/powerhome/power-tools/pull/424)
  - `TwoPercent::Domain::Events::UserCreated`, `UserUpdated`, `UserDeleted`
  - `TwoPercent::Domain::Events::GroupCreated`, `GroupUpdated`, `GroupDeleted`
  - Events include correlation_id tracking and structured attribute hashes
  - User events include groups associations in domain attributes
  - Group events include member associations in domain attributes
- **Syncable Concern**: New `TwoPercent::Syncable` concern for optional SCIM → Domain synchronization [#424](https://github.com/powerhome/power-tools/pull/424)
  - Include in your domain models to automatically sync from SCIM events
  - Block-based attribute mapping for explicit control over data transformation
  - Provides `scim_user`/`scim_group` associations and `refresh_from_scim` method
- **SCIM Models**: New `TwoPercent::ScimUser` and `TwoPercent::ScimGroup` models [#424](https://github.com/powerhome/power-tools/pull/424)
  - Query SCIM data directly: `ScimUser.find_by_scim_id("user-123")`
  - Access via associations: `scim_group.scim_users`
  - `to_domain_attributes` method for consuming SCIM data
  - `ScimUser.sync_groups` automatically syncs group memberships from SCIM payload
  - `ScimGroup.to_domain_attributes` includes member data for group events
- **PATCH Operations**: Full RFC 7644 PATCH support for partial updates to SCIM resources [#424](https://github.com/powerhome/power-tools/pull/424)
- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)

# [0.5.0] - 2025-05-29

- Make two percent authentication safe by default [#331](https://github.com/powerhome/power-tools/pull/331)
- Add logger and logger config override [#331](https://github.com/powerhome/power-tools/pull/331)
- Event params with indifferent access [#343](https://github.com/powerhome/power-tools/pull/343)

# [0.4.0] - 2025-05-15

- Add Bulk operations support [#329](https://github.com/powerhome/power-tools/pull/329)

## [0.3.0] - 2025-05-06

- Include `id` in SCIM attributes [#326](https://github.com/powerhome/power-tools/pull/326)

## [0.2.0] - 2025-03-26

- Authenticate SCIM requests [#320](https://github.com/powerhome/power-tools/pull/320)

## [0.1.0] - 2025-03-25

- Initial release firing Create, Update, Replace, and Delete events
