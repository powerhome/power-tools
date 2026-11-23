# Changelog

## [1.0.0](https://github.com/powerhome/power-tools/compare/dep_shield/v0.4.0...dep_shield/v1.0.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469))

### Added

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469)) ([21ecda2](https://github.com/powerhome/power-tools/commit/21ecda2217b909146c7a50b47a6d20e14f0b633e))


### Fixed

* **deps:** Update dependency sqlite3 to v2.10.2 [SECURITY] ([#453](https://github.com/powerhome/power-tools/issues/453)) ([44d08d6](https://github.com/powerhome/power-tools/commit/44d08d6c243883bec09809fa29124075bf322f5a))

## [0.4.0] - 2026-07-28

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Upgrade Rails to 8.1.3 for Nitro and Runway compatability
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)

---

- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Update to Rails 7.2.3.1 [#402](https://github.com/powerhome/power-tools/pull/402)

## [0.3.1]

- Cleanup unnecessary dependencies and require of rails/all

## [0.3.0]

- Subscribe to deprecation.rails notifications from railtie

## [0.2.0]

- Dynamically load todo lists

## [0.1.1]

- Fixes / navigates around different returns for YAML.load_file

## [0.1.0] - 2024-01-17

- Initial release
