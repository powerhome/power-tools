# Known limitations

These behaviors are true of DataTaster today. Keep them in mind when writing export files, and treat them as the list of
things to settle in any library that replaces DataTaster.

## Sanitization

- **Some sensitive columns are not sanitized by default.** The exception words (`ip`, `count`, `mac`, `type`, ...)
  match anywhere in a column name. So `recipient_email`, `shipping_address` and `description_note` (all containing
  `ip`) and `account_email` (`count`) keep their production values unless an export file sanitizes them.
- **The two copy paths sanitize differently.** On a server-side copy, `NULL` values, and empty strings for string
  values, are left as they are. When rows are read through the client, every row gets the sanitized value.
- **Values are guessed from their text.** A custom value containing `YYYY-MM-DD` anywhere becomes a date, and one
  containing an upper-case SQL function name anywhere (`DAY`, `TRIM`, ...) is sent as raw SQL.
- **Defaults are specific to Power.** Fake emails use `@nitrophrg.com` and addresses use `Disneyland Dr`. Neither can
  be configured.
- **Columns come from Active Record.** Default rules read columns from `ActiveRecord::Base.connection`, not from the
  source client, so they depend on that connection pointing at the source schema.

## Selecting rows

- **Unqualified table names mean different things on each path.** On a server-side copy they read the rows already
  copied to the target; otherwise they read the whole source table. DataTaster orders tables to make the first case
  work, but tables whose clauses name each other keep alphabetical order. The tables a clause names are found by
  matching words against table names, so a column or string that happens to match a table name can also change the
  order.
- **`source_db` comes from Rails.** It is the Rails `primary` database for the current environment, not the database of
  the source client.
- **A hash entry without `select:` keeps no rows**, silently.

## Copying

- **Reading through the client holds a whole table in memory.** This affects every `FileOutput` sample and any
  `DatabaseOutput` whose source is on another server. Paging the reads is still to do.
- **No schema handling.** The target must already have every table; `FileOutput` writes no schema at all.
- **No transaction.** A failed sample leaves the target partly replaced.
- **MySQL only.** SQL is written for MySQL, through `Mysql2::Client` or `Trilogy`.
- **Rails required.** The gem depends on Rails, and the default export file list comes from `Rails.root`.
- **`FileOutput` ignores `target_database`.**
