## [Unreleased]

- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)

## [1.1.0] - 2026-03-23

- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Fix duplicate observer subscriptions on Rails code reload by stopping all observers before class unload via `ActiveSupport::Reloader.before_class_unload` [#392](https://github.com/powerhome/power-tools/pull/392)

## [1.0.1] - 2025-07-31

- Add AetherObservatory::Rspec::EventHelper [#333](https://github.com/powerhome/power-tools/pull/333)
- Lazily setup default rails logger so it works [#334](https://github.com/powerhome/power-tools/pull/334)

## [0.0.1] - 2024-12-06

- Extracts AetherObservatory from Talkbox engine.
