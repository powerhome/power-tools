# Testing: tests first

Every change starts with a failing spec.

1. **Red:** write the spec, run it, see it fail for the expected reason (not a typo or missing require).
2. **Green:** least code to pass.
3. **Refactor** with the suite green; `bundle exec rake` before committing.

Commit spec with the code that passes it. Bug fixes start with a spec reproducing the bug.

## Two suites

- `rake spec`: gem's RSpec specs for the spatial behaviour it adds.
- `rake regression`: AR's own test suite with the gem loaded, for what it must not change. A failure is a gem regression until shown otherwise: rerun with `REGRESSION_BASELINE=1` (gem not loaded). Only tests that also fail on baseline may go in `regression/excludes.yml`, with reason and affected drivers. The one other allowed kind: tests checking how plain Rails treats spatial columns, which the gem changes on purpose (reason says so).
- `rake` runs both plus RuboCop; all must pass before committing.

## What and how

- **Real MySQL server.** Stubbing the connection proves nothing: don't mock adapter internals, `execute`, or query results. Doubles OK for pure Ruby collaborators (e.g. WKT/WKB parsing).
- **Both drivers.** `bundle exec rake` runs with `DB_ADAPTER=trilogy` and `DB_ADAPTER=mysql2`. Specs don't assume a driver; if behaviour truly differs, tag the spec and say why.
- **Every supported AR version.** `bundle exec appraisal <name> rake` for each appraisal touched (`rails-7-2`, `rails-8-0`, `rails-8-1`, `rails-edge`). Version checks go in code under test, never specs.
- **Public surface:** models, migrations, `schema.rb` dumps, Arel queries, `connection.columns`. Avoid asserting on private methods.
- **Port upstream tests first:** when porting from activerecord-mysql2rgeo-adapter, port its `test/cases/*_test.rb` to RSpec before the code.
- **Clean DB:** specs create and drop their own tables; any order works.
- **Start each spec file with `require "spec_helper"`** (`.rspec` is gitignored, so CI never sees a local `--require spec_helper`).
- One `describe` per class/behaviour, `context` for "when …", outcome in example name. Prefer `expect(...).to` with explicit matchers.
