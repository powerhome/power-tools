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

DataTaster uses its [Sample](https://github.com/powerhome/power-tools/blob/main/packages/data_taster/lib/data_taster/sample.rb) class to load the yml files, filtered through erb methods provided through its [Flavors](https://github.com/powerhome/power-tools/blob/main/packages/data_taster/lib/data_taster/flavors.rb) class.

Before doing so, you'll need to specify a client to use to connect to mysql and make queries. Doing so can be done by calling `DataTaster.config`, like so:

```ruby
# Example, using all defaults

    DataTaster.config(
      source_client: Mysql2::Client.new(db_config),
      working_client: Mysql2::Client.new(db_config),
    )
```

This method takes several optional arguments for further configuration of data selection. The list of arguments and their defaults can be found at `components/data_taster/lib/data_taster.rb`.

When you are ready to populate your database with the selected data, you can pass `include_insert: true` to this method call so that it returns INSERT statements. Otherwise, it will only return SELECT queries, useful for testing and debugging purposes.

Asking for samples without previously configuring db clients will result in errors. However, once you have done so, sampling is easy:

```ruby
# Example, using all defaults

DataTaster.sample!
```

This will select data from the source_client and insert it using the working_client.


 #### Deprecating Tables

 DataTaster queries directly on the source_client to retrieve the list of tables to work on, which can cause issues when tables are removed -- migrations that have run in one environment may not have yet run in another. In order to maintain smoother transitions, use the `deprecated_table` method found in the DataTaster#Flavors file to mark the table as one that should include neither the schema nor the data.
