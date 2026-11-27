# Outputs

## `DataTaster::DatabaseOutput`

```ruby
DataTaster::DatabaseOutput.new(target_client: Trilogy.new(target_config.dup))
```

Copies the sample into the target client's database. The target must already have the schema; DataTaster does not
create tables.

DataTaster processes every table the source lists in `SHOW TABLES`. Each table is copied after the tables its
`select:` clause names without a database (see [Configuration](configuration.md#tables-in-a-select-clause)); otherwise
the order is alphabetical. For each table:

| Entry | What happens on the target |
| --- | --- |
| Deprecated, or the name starts with `_` | `DROP TABLE IF EXISTS` |
| Anything else | `TRUNCATE TABLE`, then the rows the clause picks are copied and sanitized. A table without an entry keeps no rows. |

`schema_migrations` is copied in full unless an export file says otherwise, so the target's migration status matches
the source.

Every statement runs with foreign key checks off, and the previous setting is restored afterwards.

How the rows are copied depends on where the source and target are. DataTaster compares `@@server_uuid` on both
connections once per source:

- **Same server.** Each table is copied with `INSERT INTO target.table SELECT * FROM source.table WHERE ...` on the
  target connection, then sanitized with `UPDATE`s. The rows never pass through Ruby, so this works for tables of any
  size.
- **Different servers, or the server can't report its UUID.** Each table's rows are read into Ruby, then written to the
  target as sanitized `INSERT`s of 100 rows each. Neither Trilogy nor Mysql2 streams these reads, so the whole
  selected result is held in memory, and a large table can use more memory than the process has.

The two paths sanitize `NULL` and empty values differently. See [Sanitization](sanitization.md#when-values-are-applied).

## `DataTaster::FileOutput`

```ruby
DataTaster::FileOutput.new(path: "dump.sql", target_database: "my_db")
```

Writes the sample to a SQL file instead of a database. The file holds:

- `SET FOREIGN_KEY_CHECKS=0;` first and `SET FOREIGN_KEY_CHECKS=1;` last.
- Sanitized `INSERT INTO \`table\` (...) VALUES ...;` statements of up to 100 rows, with table names left without a
  database so the file can be loaded into any database.

It holds no schema, `TRUNCATE` or `DROP` statements. Load it into a database that already has the schema and empty
tables.

Only the tables listed in the export files are written, in the order the export files list them. Deprecated tables are
left out, and `schema_migrations` is only written if an export file lists it. Rows are always read through the client,
so the memory limit above applies to every table. `target_database` is accepted but not used in the file.
