# 🍭 Data Taster

Database exporting tool.

## Usage

### `data_taster_export_tables.yml`

With DataTaster, you can configure certain tables and rows to be pulled from the source_db. Look for (or create) a `data_taster_export_tables.yml` file anywhere in your repo (for example, this could live under `config/` or `db/`).

By default, any table that has nothing specified in the files will not have any data selected from the source client.

Each key should represent the table name that you are defining rules for. If you don't have any custom rows to sanitize, the value should be a clause that will be wrapped in a MySQL WHERE clause. DataTaster will automatically look for any files with that name and include them in the export.

```ruby
# Example, simple usage

sales_summaries: quarter_start_date >= '<%= Date.current.last_year.beginning_of_quarter %>'
```

If you have columns that you need to sanitize, you'll need to specify the column names and values along with the selections. Note that many things get sanitized by default.

```ruby
# Example, with sanitization specified

sales_summaries:
  select: "quarter_start_date >= '<%= Date.current.last_year.beginning_of_quarter %>'"
  sanitize:
    comp_total: 9999.99
```

### Default Sanitization

To help protect data, DataTaster scans columns that it's importing against of blocklist of terms that it identifies as high risk (you can see the full list of default sanitizations at `lib/data_taster/sanitizer.rb`.). If the term is a match against its list and there is no custom sanitization defined, it will attempt to sanitize the column. If you do not need to sanitize that column, you can always skip it:

```ruby
users:
  select: "activated_at IS NOT NULL"
  sanitize:
    retain_email: "<%= skip_sanitization %>"
```

### `DataTaster.sample!`

DataTaster loads the yml files through erb methods provided by its [Flavors](https://github.com/powerhome/power-tools/blob/main/packages/data_taster/lib/data_taster/flavors.rb) class.

Before sampling, configure a source to read from and an output to write to with `DataTaster.setup`. Clients can be either `Mysql2::Client` or `Trilogy` connections:

```ruby
DataTaster.setup(
  source: DataTaster::MysqlSource.new(source_client: Trilogy.new(source_config.dup)),
  output: DataTaster::DatabaseOutput.new(target_client: Trilogy.new(target_config.dup)),
)
```

`setup` also accepts `months:` (how far back `recent_table_updates` looks) and `list:` (the yml files to load, defaulting to every `data_taster_export_tables.yml` under `Rails.root`).

To write a SQL file instead of loading a database, use `DataTaster::FileOutput.new(path: "dump.sql", target_database: "my_db")` as the output.

Once configured, sampling is easy:

```ruby
DataTaster.sample!
```

This selects data from the source and writes it, sanitized, to the output.


 #### Deprecating Tables

 DataTaster queries directly on the source_client to retrieve the list of tables to work on, which can cause issues when tables are removed -- migrations that have run in one environment may not have yet run in another. In order to maintain smoother transitions, use the `deprecated_table` method found in the DataTaster#Flavors file to mark the table as one that should include neither the schema nor the data.
