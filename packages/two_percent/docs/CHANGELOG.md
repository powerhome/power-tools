## [Unreleased]

## [1.3.0]- 2026-06-26

- **BREAKING - Thin Domain Events**: Removed association data from domain events
  - User events (`UserCreated`, `UserUpdated`) no longer include `groups` array in `user_attributes`
  - Group events (`GroupCreated`, `GroupUpdated`) no longer include `members` array in `group_attributes`
- **Performance - Group Membership Updates**: Optimized `ScimGroup.replace_members` for large groups (10k+ members)
  - Calculates diff (members to add/remove) before validation
  - Only validates NEW members instead of all existing members
- **Configuration**: New `config.include_members_in_patch_response` option (default: `true`)
  - Set to `false` to exclude `members` array from PATCH Group response bodies for improved performance
  - Useful when SCIM clients don't need member data in response (reduces payload size and query overhead)

## [1.2.0] - 2026-06-17

- **Simplify ScimGroupMembership**: Removed correlation_id from join table (tracking remains on ScimGroup and ScimUser)

## [1.1.0] - 2026-06-05

- **GET Endpoints**: Read operations with RFC 7644 ListResponse format [#436](https://github.com/powerhome/power-tools/pull/436)
  - `GET /scim/:resource_type/:id` - Single resource retrieval
  - `GET /scim/:resource_type` - List/search resources with pagination
  - RFC 7644 ListResponse format: `{schemas, totalResults, startIndex, itemsPerPage, Resources}`
  - Legacy query filtering: `?query=` parameter for display_name substring match (case-insensitive)
  - SCIM pagination: `?startIndex=` (1-based) and `?count=` parameters (default: 100, max: 1000)
  - Supports all configured resource types (Users + configured group types)
  - Eager loading of associations (users → groups, groups → members)
  - No domain events published for read operations
  - Note: RFC 7644 `filter`, `sortBy`, and `attributes` parameters not yet supported
- **Configurable Group Resource Types**: `config.group_resource_types` setting [#436](https://github.com/powerhome/power-tools/pull/436
  - Defaults to `%w[Groups]` (SCIM standard type only)
  - Configure additional types (e.g., Departments, Territories) in initializer

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
