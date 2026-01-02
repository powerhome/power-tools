## [Unreleased]

- Adds Migration/AcknowledgeIgnoredColumn cop [#382](https://github.com/powerhome/power-tools/pull/382)
- Extends Migration/RenameColumn to cover uses in a change_table [#381](https://github.com/powerhome/power-tools/pull/381)
- Adds Migration/RenameColumn and Migration/RenameTable cops [#380](https://github.com/powerhome/power-tools/pull/380)
- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)

## [0.5.6] - 2025-09-09

- Bump Rubocop version to unblock dependabot in repos

## [0.5.5] - 2025-04-22

- Fix Rubocop base class inheritance [#323](https://github.com/powerhome/power-tools/pull/323)

## [0.5.4] - 2025-03-18

- Bump Rubocop version to bring in bugfixes.

## [0.5.2] - 2023-02-08

- Permit Rubocop upgrades again because bug was fixed.

## [0.5.1] - 2023-02-08

- Hold back version of Rubocop that's permitted due to incompatibility with our implementation.

## [0.5.0] - 2022-07-22

### Features

- Provide style guide references and helpful hints on violations. (#36)
- Ignore Metrics/BlockLength on Rspec's context and describe (#43)

### Documentation

- Fix rel links in README (#37)
- Initial portal setup (#34)

### Updates

- Lock file maintenance
- Update tj-actions/changed-files action to v24 (#47)
- Update dependency rubocop to ~> 1.32.0 (#46)
- Update dependency babel-eslint to v10 (#45)
- Update all non-major dependencies (#44)
- Update typescript-eslint monorepo to v5 (major) (#24)
- Update dependency eslint-webpack-plugin to v3 (#23)
- Update dependency eslint-plugin-jsx-control-statements to v3 (#22)
- Update dependency eslint-plugin-flowtype to v8 (#21)
- Update dependency babel-eslint to v10 (#19)
- Update all non-major dependencies (#16)
- Pin dependency babel-eslint to v (#15)

## [0.4.1] - 2022-06-02

- Fix bug in Naming/ViewComponent when class does not inherit

## [0.4.0] - 2022-06-01

- Adds Naming/ViewComponent cop
- Adds Style/NoHelpers cop

## [0.1.0] - 2022-05-18

- Initial release
