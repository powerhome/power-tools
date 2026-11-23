# Changelog

## [2.0.0](https://github.com/powerhome/power-tools/compare/aether_observatory/v1.2.0...aether_observatory/v2.0.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469))

### Added

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469)) ([21ecda2](https://github.com/powerhome/power-tools/commit/21ecda2217b909146c7a50b47a6d20e14f0b633e))


### Fixed

* **deps:** Update dependency bundler to v4 ([#385](https://github.com/powerhome/power-tools/issues/385)) ([22747e5](https://github.com/powerhome/power-tools/commit/22747e50fe6ed8fe9021e71415044e71b51a588e))

## [1.2.0] - 2026-07-28

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Upgrade Rails to 8.1.3 for Nitro and Runway compatability
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Update yard to 0.9.38 to address [Cross-site Scripting vulnerability](https://github.com/powerhome/power-tools/security/dependabot/544) [#394](https://github.com/powerhome/power-tools/pull/394)

## [1.1.0] - 2026-03-23

- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Fix duplicate observer subscriptions on Rails code reload by stopping all observers before class unload via `ActiveSupport::Reloader.before_class_unload` [#392](https://github.com/powerhome/power-tools/pull/392)

## [1.0.1] - 2025-07-31

- Add AetherObservatory::Rspec::EventHelper [#333](https://github.com/powerhome/power-tools/pull/333)
- Lazily setup default rails logger so it works [#334](https://github.com/powerhome/power-tools/pull/334)

## [0.0.1] - 2024-12-06

- Extracts AetherObservatory from Talkbox engine.
