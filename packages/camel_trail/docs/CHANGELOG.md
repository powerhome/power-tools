# Changelog

## [2.0.0](https://github.com/powerhome/power-tools/compare/camel_trail/v1.3.0...camel_trail/v2.0.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469))

### Added

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469)) ([21ecda2](https://github.com/powerhome/power-tools/commit/21ecda2217b909146c7a50b47a6d20e14f0b633e))


### Fixed

* **deps:** Update dependency sqlite3 to v2.10.2 [SECURITY] ([#453](https://github.com/powerhome/power-tools/issues/453)) ([44d08d6](https://github.com/powerhome/power-tools/commit/44d08d6c243883bec09809fa29124075bf322f5a))

## [1.3.0] - 2026-07-28

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Add support for Rails 8+ for Nitro and Runway compatability

## [1.2.1] - 2026-06-24

- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Update yard to 0.9.38 to address [Cross-site Scripting vulnerability](https://github.com/powerhome/power-tools/security/dependabot/544) [#394](https://github.com/powerhome/power-tools/pull/394)
- Update Rails version to 7.2.3.1 for Active Storage CVE [#402](https://github.com/powerhome/power-tools/pull/402)
- Expose the notes and activity fields to be saved as any value [#410](https://github.com/powerhome/power-tools/pull/410)

## [1.2.0] - 2025-07-31

- Add support to rails 7.2 [#351](https://github.com/powerhome/power-tools/pull/351)

## [1.1.0] - 2025-02-18

- Prevents creating records with empty `source_changes` [#307](https://github.com/powerhome/power-tools/pull/307)
- Support keyword arguments for serialization [#308](https://github.com/powerhome/power-tools/pull/308)
- Drop rails 6.0 support and adds Rails 7.0 to CI [#309](https://github.com/powerhome/power-tools/pull/309)

## [1.0.0] - 2024-02-28

- Adds support for Rails 7.1
- Uses upstream `attr_encrypted` gem

## [0.0.2] - 2023-01-08

- Bugfixes, minor version bumps

## [0.0.1] - 2023-03-20

- Extracts NitroHistory main functionality into CamelTrail
