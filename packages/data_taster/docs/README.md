# 🍭 Data Taster

DataTaster copies a small, sanitized sample of a MySQL database into another database or a SQL file, for development
and demo environments.

You say which rows of each table to keep in `data_taster_export_tables.yml` files. DataTaster copies those rows,
replaces sensitive values (emails, addresses, SSNs, birth dates, notes, and so on) with fake ones, and leaves every
other table empty.

## Requirements

- Ruby 3.0 or later (CI runs 3.3) and Rails 7.1.3.2 to 8.2. DataTaster uses Active Record and Active Support, and
  reads the default list of export files from `Rails.root`.
- MySQL. Each connection is a `Mysql2::Client` or a `Trilogy` client. Neither gem is a dependency of DataTaster, so
  add the one you use to your Gemfile.
- An Active Record connection that can see the source tables. Default sanitization reads each table's columns from
  `ActiveRecord::Base.connection` (see [Sanitization](sanitization.md)).
- For a database output, a target database that already has the schema. DataTaster empties and fills tables, but
  never creates them.

## Quick start

Describe the rows to keep, in a `data_taster_export_tables.yml` anywhere in your app (for example `config/` or `db/`):

```yaml
---
users: "<%= recent_table_updates %>"
projects: "<%= full_table_dump %>"
sales_summaries:
  select: "quarter_start_date >= '<%= Date.current.last_year.beginning_of_quarter %>'"
  sanitize:
    comp_total: 9999.99
```

Point DataTaster at a source and an output, then sample:

```ruby
DataTaster.setup(
  source: DataTaster::MysqlSource.new(source_client: Trilogy.new(source_config.dup)),
  output: DataTaster::DatabaseOutput.new(target_client: Trilogy.new(target_config.dup)),
  months: 3,
)

DataTaster.sample!
```

`DataTaster.setup` takes:

| Option | Description |
| --- | --- |
| `source:` | A `DataTaster::MysqlSource` wrapping the client to read from. |
| `output:` | A `DataTaster::DatabaseOutput` or `DataTaster::FileOutput`. See [Outputs](outputs.md). |
| `months:` | How far back `date`, `recent_table_updates` and `recent_ids` look. One week when not set. |
| `list:` | The export files to load. Defaults to every `data_taster_export_tables.yml` under `Rails.root`. |

`DataTaster.sample!` writes every table to the output. It logs each table and each statement to `DataTaster.logger`,
which is a `Logger` on `$stdout` unless you set `DataTaster.logger = ...`. `DataTaster.reset!` forgets the setup and
the loaded export files.

## Documentation

- [Configuration](configuration.md): the export files, select clauses, and the ERB helpers.
- [Sanitization](sanitization.md): the default rules, custom values, and skipping a column.
- [Outputs](outputs.md): copying into a database or writing a SQL file.
- [How it works](how-it-works.md): what happens to each table during a sample.
- [Known limitations](limitations.md): behavior to know about, and to fix in a successor.
