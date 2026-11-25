# Configuration

## Export files

DataTaster reads the files given to `DataTaster.setup(list:)`, or every `data_taster_export_tables.yml` under
`Rails.root` when `list:` is not given. Each file is rendered as ERB and then parsed as YAML. Everything up to the last
`---` in the file is dropped before parsing, so a file can start with notes above a `---` line. A `---` inside an
entry, such as in a SQL comment, drops the entries above it too.

The files are merged into one hash keyed by table name. When two files name the same table, the file loaded later
replaces the whole entry; `select:` and `sanitize:` are not merged separately. Default files are loaded in path order.

### Table entries

Each key is a table name. Its value is one of:

| Value | Meaning |
| --- | --- |
| A string | The `WHERE` clause that picks the rows to keep. |
| A hash | `select:` holds the `WHERE` clause; `sanitize:` holds [custom sanitization](sanitization.md). A hash without `select:` keeps no rows. |
| `<%= deprecated_table %>` | Skip the table entirely. A database output drops it from the target. |
| Nothing (no key, or an empty value) | Keep no rows. A database output empties the table but keeps it. |

```yaml
---
# Keep every row
projects: "<%= full_table_dump %>"

# Keep rows picked by a clause
sales_summaries: "quarter_start_date >= '<%= Date.current.last_year.beginning_of_quarter %>'"

# Keep rows and override how columns are sanitized
users:
  select: "activated_at IS NOT NULL"
  sanitize:
    notes: "Notes removed"
    retain_email: "<%= skip_sanitization %>"

# Removed by a migration that may not have run everywhere yet
legacy_reports: "<%= deprecated_table %>"
```

DataTaster wraps the clause as `SELECT * FROM <source database>.<table> WHERE <clause>`, so any MySQL expression
works, subqueries included.

Tables whose names start with `_` (for example the tables online schema change tools leave behind) are always
skipped, as if they were deprecated.

With a database output, every table is processed, listed or not. With a file output, only the tables listed in the
export files are. See [Outputs](outputs.md).

### Tables in a `select:` clause

A clause can name other tables, usually to keep rows that belong to rows kept elsewhere:

```yaml
---
phone_numbers: "id IN (SELECT phone_number_id FROM <%= source_db %>.users WHERE <%= recent_table_updates %>)"
phones: "phone_number_id IN (SELECT id FROM phone_numbers)"
```

A table named **with** a database (`<%= source_db %>.users`) is always read in full from the source.

A table named **without** a database is read from whichever database the `SELECT` runs on:

- When a `DatabaseOutput` copies on the server (the source and target share a MySQL server), the `SELECT` runs on the
  target. `phone_numbers` then means the rows already copied to the target, so `phones` keeps only the phones of the
  kept numbers. DataTaster copies each table after the tables its clause names this way. Tables whose clauses name
  each other keep alphabetical order.
- Otherwise, the `SELECT` runs on the source, and `phone_numbers` means the whole source table.

Name the database whenever you mean the whole source table, so the clause means the same thing on both paths.

## ERB helpers

Export files are rendered with the methods of `DataTaster::Flavors` (and `DataTaster::Helper`) in scope.

| Helper | Returns |
| --- | --- |
| `full_table_dump` | `1 = 1`, which keeps every row. |
| `recent_table_updates` | `created_at >= '<date>' OR updated_at >= '<date>'`. |
| `recent_ids(table, column)` | A subquery of the distinct `column` values of the rows of `<source_db>.table` created or updated since `date`. |
| `date` | The start of the day `months` months ago (one week ago when `months` is not set), formatted for SQL. |
| `current_date` | `Date.current`. |
| `source_db` | The database name of the Rails `primary` configuration for the current environment. |
| `deprecated_table` | The marker that skips a table. |
| `skip_sanitization` | The marker that leaves a column unsanitized. |
| `encrypt(klass, column, value = nil)` | `value` encrypted the way `klass` encrypts `column`, for sanitizing encrypted columns. Needs `attr_encrypted` (or a model that responds to `encrypt`). Without `value`, a placeholder is chosen from the column name: a date 25 years ago for `dob`/`date_of_birth`, `111111111` for `ssn`/`license`, `1` for `compensation`, and `"1"` for anything else. |

Wrap dates and other strings in quotes inside the clause, as in `"created_at >= '<%= date %>'"`.

`source_db` comes from the Rails configuration, not from the client given to `MysqlSource`. Make sure both name the
same database.
