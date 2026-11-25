# How it works

This page describes how a sample is produced, for people changing DataTaster or building on it.

## Pieces

| Class | Role |
| --- | --- |
| `DataTaster` | Holds the setup (`Config`: source, output, months, list), the merged export files, and the logger. `sample!` hands off to the output. |
| `DataTaster::Confection` | Renders each export file with `Flavors` and merges them, on top of the output's `default_data`. |
| `DataTaster::Flavors`, `DataTaster::Helper` | The methods available inside export files. |
| `DataTaster::Collection` | One table's entry: whether to skip it, the `SELECT` that picks its rows, and its `sanitize:` hash. |
| `DataTaster::TableOrder` | Puts the tables a `select:` clause names without a database before that table. |
| `DataTaster::Sanitizer` | Works out each column's sanitized value (defaults plus `sanitize:`), and either runs the `UPDATE`s or hands rows to the exporter. |
| `DataTaster::Detergent` | Turns one column's value into an `UPDATE` statement or an `INSERT` value. |
| `DataTaster::SanitizerExporter`, `DataTaster::ExportContext` | Read a table's rows from the source and build sanitized `INSERT`s, 100 rows at a time. |
| `DataTaster::SqlLiteral` | Formats Ruby values as MySQL literals, including binary columns as hex. |
| `DataTaster::MysqlSource` | The source: its client, database and tables. |
| `DataTaster::Output`, `DatabaseOutput`, `FileOutput` | Where the sample goes. |
| `DataTaster::Adapters` | Gives a `Trilogy` client the parts of the `Mysql2::Client` interface DataTaster uses. Trilogy reports no column types, so binary values are told apart by their encoding. |

## A sample, step by step

1. `DataTaster.setup` stores the source, output, `months` and export file list, and forgets any export files loaded
   before.
2. `DataTaster.sample!` calls `output.sample!`.
3. The output picks its tables. `DatabaseOutput` takes the source's `SHOW TABLES` list and orders it with
   `TableOrder`. `FileOutput` takes the keys of the export files.
4. The export files are loaded the first time an entry is needed: `Confection` renders and merges them, starting from
   the output's `default_data` (`schema_migrations: "1 = 1"` for a database output).
5. For each table, `Collection#assemble` returns nothing for a skipped table, or the `SELECT` and the `sanitize:` hash.
6. The output writes the table:
   - `DatabaseOutput` drops a skipped table. For any other table, it truncates the target table, then:
     - on the same server, runs `INSERT INTO target.table SELECT ...` on the target and then `Sanitizer#clean!`, which
       runs one `UPDATE` per sanitized column. If that fails, it truncates the table again and raises.
     - otherwise, runs the `SELECT` on the source and writes the `INSERT`s that `Sanitizer#export_sanitized_rows`
       builds.
   - `FileOutput` writes the `INSERT`s that `Sanitizer#export_sanitized_rows` builds, and skips skipped tables.

Nothing runs in a transaction. If a sample fails halfway, the tables before the failing one are already replaced, and
the rest are unchanged.
