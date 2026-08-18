## [Unreleased]

## [0.0.1] - 2026-08-12

- Initial release: a global registry of named destinations, so any component can link to any page
  without depending on the component that owns the route.
- `register` / `path_for` / `url_for` for cross-component links.
- `define_kind` / `of_kind` / `accessible_by` for lists of destinations carrying an ability check and
  display metadata.
- `verify!` for boot-time assertion that expected destinations are registered.
- `wayfinding/rspec` for registry isolation and stubbing in specs.
