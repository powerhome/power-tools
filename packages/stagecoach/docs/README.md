# Stagecoach

A read-only ActiveRecord SQL adapter for [Trino](https://trino.io/), built on top of the [`trino-client`](https://rubygems.org/gems/trino-client) gem.

Stagecoach lets a Rails application query a Trino data warehouse using familiar ActiveRecord scopes and `where` chains while preventing accidental writes. It is designed for analytical use cases where the warehouse is the source of truth and the application only needs to read from it.

## Features

- **Read-only by design.** All write paths (`insert`, `update`, `delete`, transactions, migrations, schema changes) raise `Stagecoach::ReadOnlyError`.
- **ActiveRecord-native.** Plugs into Rails 7.1+ multi-database via `database.yml` and `connects_to`.
- **Opinionated safety belts.** `find_each` / `find_in_batches` are banned (they don't fit Trino's pagination model); hard query timeouts default to 60 seconds; slow queries emit `ActiveSupport::Notifications` for any subscriber to pick up.
- **SQL-injection conscious.** Trino has no parameterized queries, so every literal flows through a tight, fuzz-tested `quote` implementation.
- **Schema introspection** via Trino's `information_schema.columns`, with a small but practical type map (varchar, integer, decimal, boolean, date, timestamp, timestamp with time zone, json, etc.).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "stagecoach"
```

Then in your `config/database.yml`:

```yaml
warehouse:
  adapter: trino
  server: <%= ENV["TRINO_SERVER"] %>
  user: <%= ENV["TRINO_USER"] %>
  password: <%= ENV["TRINO_PASSWORD"] %>
  catalog: <%= ENV["TRINO_CATALOG"] %>
  schema: <%= ENV["TRINO_SCHEMA"] %>
  query_timeout: 60
  plan_timeout: 10
```

And an abstract record that connects to it:

```ruby
class WarehouseRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { reading: :warehouse }
end

class SalesByDay < WarehouseRecord
  self.table_name = "sales_by_day"
end
```

Now standard AR queries work against Trino:

```ruby
SalesByDay.where(month: "2026-04").order(:territory_id).limit(100)
```

## What is and is not supported

Supported:
- `where`, `order`, `limit`, `offset`, `select`, `pluck`, `find_by`, `count`, `sum`, `average`
- Scopes, including chained scopes
- Type-cast reads for varchar, integer (all widths), real/double, decimal, boolean, date, timestamp, timestamp with time zone, time, json, uuid

Not supported (raises):
- Any write path: `save`, `update`, `delete`, `destroy`, `insert`, `create_table`, transactions, savepoints
- `find_each` / `find_in_batches` — Trino's pagination model is incompatible; use explicit `LIMIT`/`OFFSET` or `pluck` aggregates
- Trino composite types (`array`, `map`, `row`) in result casting — select scalar columns or extract via Trino SQL (`element_at`, dot access)

Out of design scope:
- `joins` are not a design goal. The adapter passes SQL through to Trino, so a join across two Trino-backed models technically works, but it is not tested and the intended usage pattern is to query flat denormalized warehouse tables.
- Cross-database joins (e.g., a MySQL model joined to a Trino model) do not work — Rails 7.1+ disallows joins across connection handles.

## Configuration options

All keys are read from the `database.yml` entry:

| Key | Default | Description |
|---|---|---|
| `server` | _required_ | Trino server URL (e.g. `https://trino.example.com:8443`) |
| `user` | _required_ | Trino user |
| `password` | _nil_ | Optional basic-auth password |
| `catalog` | _required_ | Default Trino catalog |
| `schema` | _required_ | Default Trino schema |
| `ssl` | _nil_ | Boolean or hash forwarded to `trino-client` |
| `query_timeout` | `60` | Hard ceiling on query duration, in seconds |
| `plan_timeout` | `10` | Ceiling on Trino query-planning phase, in seconds |
| `slow_query_threshold_seconds` | `5` | Threshold above which a `stagecoach.slow_query` notification is emitted |

## Instrumentation

Stagecoach uses ActiveRecord's standard `AbstractAdapter#log` for query instrumentation, so any `ActiveSupport::Notifications` subscriber on `sql.active_record` picks up Trino queries automatically.

In addition, queries exceeding `slow_query_threshold_seconds` emit a `stagecoach.slow_query` notification with payload `{ sql:, duration:, name: }`.

## Development

1. Clone the repository.
2. Install dependencies: `bundle install`.
3. Run the test suite: `bundle exec rspec`.
4. Run the linter: `bundle exec rubocop`.

### Testing changes locally in another app

```ruby
# In the consuming application's Gemfile
gem "stagecoach", path: "path/to/packages/stagecoach"
```

## License

This project is licensed under the MIT License — see the [LICENSE.txt](../LICENSE.txt) file for details.
