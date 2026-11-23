# Changelog

## [1.0.0](https://github.com/powerhome/power-tools/compare/lumberaxe/v0.3.0...lumberaxe/v1.0.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469))

### Added

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469)) ([21ecda2](https://github.com/powerhome/power-tools/commit/21ecda2217b909146c7a50b47a6d20e14f0b633e))


### Fixed

* **deps:** Update dependency bundler to v4 ([#385](https://github.com/powerhome/power-tools/issues/385)) ([22747e5](https://github.com/powerhome/power-tools/commit/22747e50fe6ed8fe9021e71415044e71b51a588e))
* **deps:** Update dependency sqlite3 to v2.10.2 [SECURITY] ([#453](https://github.com/powerhome/power-tools/issues/453)) ([44d08d6](https://github.com/powerhome/power-tools/commit/44d08d6c243883bec09809fa29124075bf322f5a))

## [0.3.0] - 2026-07-28

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Upgrade Rails to 8.1.3 for Nitro and Runway compatability
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Update yard to 0.9.38 to address [Cross-site Scripting vulnerability](https://github.com/powerhome/power-tools/security/dependabot/544) [#394](https://github.com/powerhome/power-tools/pull/394)
- Update rainbow to v3.x [#372](https://github.com/powerhome/power-tools/pull/372)
- Update Rails version to 7.2.3.1 for Active Storage CVE [#402](https://github.com/powerhome/power-tools/pull/402)

## [0.2.0] - 2025-08-15

- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)

## [0.1.5] - 2024-1-17

- Add support to rails 7.1

## [0.1.4] - 2023-1-1

- Add LoggerSilence module to fix sprockets-rails compatibility

## [0.1.3] - 2022-10-18

- Fix tag keys on log formatter

## [0.1.2] - 2022-09-09

- Ensure logging works without rails environments

## [0.1.1] - 2022-07-28

- Handles logging output formatting.
