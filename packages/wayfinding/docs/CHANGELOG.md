# Changelog

## [1.0.0](https://github.com/powerhome/power-tools/compare/wayfinding/v0.0.1...wayfinding/v1.0.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469))

### Added

* fix custom cop bugs and convert rubocop-cobra and rubocop-powerhome to RuboCop plugins [HFH-5249] ([#469](https://github.com/powerhome/power-tools/issues/469)) ([21ecda2](https://github.com/powerhome/power-tools/commit/21ecda2217b909146c7a50b47a6d20e14f0b633e))


### Fixed

* **deps:** Update dependency bundler to v4 ([#385](https://github.com/powerhome/power-tools/issues/385)) ([22747e5](https://github.com/powerhome/power-tools/commit/22747e50fe6ed8fe9021e71415044e71b51a588e))

## [0.0.1] - 2026-08-12

- Initial release: a global registry of named destinations, so any component can link to any page
  without depending on the component that owns the route.
- `register` / `path_for` / `url_for` for cross-component links.
- `define_kind` / `of_kind` / `accessible_by` for lists of destinations carrying an ability check and
  display metadata.
- `verify!` for boot-time assertion that expected destinations are registered.
- `wayfinding/rspec` for registry isolation and stubbing in specs.
