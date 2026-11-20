## [Unreleased]

- **Breaking:** Remove `Cobra/HelperFilePlacement`. It told developers to namespace helpers that `Style/NoHelpers` (rubocop-powerhome) says should not exist. Configuration that still names it now fails with a message pointing to `Style/NoHelpers`; delete those entries (e.g. from `.rubocop_todo.yml`)
- `Cobra/GemRequirement` now checks every `path ".."` block wherever it appears in the Gemfile, including gems nested in a `group` and gems with other options alongside `require: nil`. Previously it only checked a path block that was the last statement in the file
- Fix `Cobra/Inheritance` allowing a top-level `::ApplicationRecord` (or other protected constant) with a leading `::`
- Anchor the file placement cops on `components/<name>/<dir>/`. A `lib/` or `components/` elsewhere in the path (a parent directory, a component named `pdf_lib`, `app/lib/`) no longer triggers false offenses, and `Cobra/ViewComponentFilePlacement` ignores files outside a component
- Run the previously skipped `Cobra/DependencyVersion` spec, and reword its message: it applies to every gemspec dependency, not only external components
- Fix `rubocop --debug` crashing with `undefined method 'logger' for module RuboCop::Rails`

## [0.5.0] - 2026-07-28

[HFH-4410 - Bump powertools for Rails 8.1.3 V2](https://github.com/powerhome/power-tools/pull/426)

- Upgrade Rails to 8.1.3 for Nitro and Runway compatability
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)

## [0.4.7] - 2026-01-05

- Bump Rubocop version to keep in parallel with rubocop-powerhome.

## [0.4.6] - 2025-09-09

- Bump Rubocop version to unblock dependabot in repos
- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)

## [0.4.5] - 2025-04-22

- Fix Rubocop base class inheritance [#323](https://github.com/powerhome/power-tools/pull/323)

## [0.4.4] - 2023-03-18

- Bump Rubocop version to bring in bugfixes.

## [0.4.2] - 2023-02-08

- Permit Rubocop upgrades again because bug was fixed.

## [0.4.1] - 2023-02-08

- Hold back version of Rubocop that's permitted due to incompatibility with our implementation.

## [0.4.0] - 2022-06-01

- Adds Cobra/ViewComponentFilePlacement cop

## [0.1.0] - 2022-05-18

- Initial release
