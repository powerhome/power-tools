# Testing: tests first

Every change starts with a failing spec.

1. **Red.** Write the spec that describes the behaviour, run it, and see it fail
   for the expected reason, not because of a typo or a missing require.
2. **Green.** Write the least code that makes it pass.
3. **Refactor.** Clean up with the suite green. Run `bundle exec rake` before
   committing.

Commit the spec together with the code that makes it pass. A bug fix starts with
a spec that reproduces the bug.

## Two suites

- `rake spec`: this gem's RSpec specs, for the spatial behaviour it adds.
- `rake regression`: Active Record's own test suite with the gem loaded, for
  everything it must not change. A failure here is a regression in the gem
  until shown otherwise: rerun the failing test with `REGRESSION_BASELINE=1`
  (gem not loaded). Only a test that fails on the baseline too may go in
  `regression/excludes.yml`, with its reason and the drivers it affects. The
  one other kind allowed there is a test that checks how plain Rails treats
  spatial columns, which this gem changes on purpose; its reason says so.
- `rake` runs both, plus RuboCop. All of it must pass before committing.

## What to test and how

- **Hit a real MySQL server.** This gem changes how Active Record talks to MySQL,
  so stubbing the connection proves nothing. Don't mock adapter internals,
  `execute`, or query results. Doubles are fine for pure Ruby collaborators
  such as WKT/WKB parsing.
- **Both drivers, always.** `bundle exec rake` runs the suite once with
  `DB_ADAPTER=trilogy` and once with `DB_ADAPTER=mysql2`. Specs must not assume
  a driver. When behaviour really differs, tag the spec and say why.
- **Every supported Active Record version.** Run
  `bundle exec appraisal <name> rake` for each appraisal touched by the change
  (`rails-7-2`, `rails-8-0`, `rails-8-1`, `rails-edge`). Version checks belong in
  the code under test, never in specs.
- **Test behaviour through the public surface:** models, migrations, `schema.rb`
  dumps, Arel queries, `connection.columns`. Avoid asserting on private methods.
- **Port upstream tests first.** When porting a feature from
  activerecord-mysql2rgeo-adapter, port its tests (`test/cases/*_test.rb`) to
  RSpec before porting the code. They describe the behaviour we must keep.
- **Leave the database clean.** Specs create the tables they need and drop them
  afterwards, so they can run in any order.
- **Start every spec file with `require "spec_helper"`.** The repository ignores
  `.rspec`, so CI never sees a local `--require spec_helper`.
- Use one `describe` per class or behaviour, `context` for "when …", and say the
  outcome in the example name. Prefer `expect(...).to` with explicit matchers.
