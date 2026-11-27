# Sanitization

Every table that has an entry in the export files is sanitized: columns whose names look sensitive get default fake
values, and the entry's `sanitize:` hash adds or overrides values per column. Tables without an entry keep no rows, so
they have nothing to sanitize.

DataTaster finds a table's columns through `ActiveRecord::Base.connection.schema_cache`, so the default Active Record
connection must be able to see every table that has an entry.

## Default rules

Each column name is checked against these patterns, in this order, and the first match wins. Most patterns ignore a
column whose name contains any of `_id`, `_at`, `type`, `subject`, `ip`, `mac`, `remote`, `count`, `encrypted` or
`voice` anywhere in it.

| Column name contains | Ignored when it also contains | Value |
| --- | --- | --- |
| `encrypted` | | `NULL` |
| `ssn`, `passport` or `license` | the common exceptions | `111111111` |
| `dob` or `birth` | the common exceptions | The date 29 years ago |
| `note` or `body` | the common exceptions | `Redacted for privacy` |
| `compensation` or `income` | the common exceptions | `999999` |
| `email` | the common exceptions, or `2` | `CONCAT('<table>_', id, '@nitrophrg.com')` |
| `email` and ends in `2` | | `CONCAT('<table>_', id, '_2', '@nitrophrg.com')` |
| `address` | the common exceptions, `2` or `email` | `CONCAT(id, ' Disneyland Dr')` |
| `address`, followed later by `2` | the common exceptions, or `email` | `Unit M` |

The exceptions match anywhere in the name, not only as whole words, so some sensitive columns are left alone. For
example `recipient_email` and `shipping_address` contain `ip`, and `account_email` contains `count`. Check your
sensitive columns and sanitize them explicitly. See [Known limitations](limitations.md).

The full list lives in `DataTaster::Sanitizer#defaults`.

## Custom values

`sanitize:` maps a column to the value it should hold. A custom value always overrides the default for that column.

```yaml
---
users:
  select: "activated_at IS NOT NULL"
  sanitize:
    comp_total: 9999.99
    nickname: "Jane"
    hired_on: "2020-01-01"
    login: "CONCAT('user_', id)"
    middle_name: ""
    retain_email: "<%= skip_sanitization %>"
```

How a value is read:

| Value | Written as |
| --- | --- |
| A number | The number. |
| A string containing a date (`YYYY-MM-DD`) | That date. |
| A string containing `CONCAT`, `DATE`, `DAY`, `FORMAT`, `LOWER`, `REPLACE`, `TRIM`, `UCASE` or `UPPER` | A SQL expression. It can use the row's other columns, such as `id`. |
| An empty string or nothing | `NULL`. |
| Any other string | The string. |
| `<%= skip_sanitization %>` | The column is left as it is, even if a default rule matches it. |

The date and SQL checks look for those patterns anywhere in the string, and the SQL check is case-sensitive. So
`"Unit 2020-01-01"` becomes a date, and `"SUNDAY"` is sent as SQL. Pick plain values that avoid them.

## When values are applied

The rows are sanitized in one of two ways, depending on how the output copies them (see [Outputs](outputs.md)):

- **Copied on the server.** The rows are copied as they are, then each sanitized column is changed with an `UPDATE`.
  Values that are `NULL` stay `NULL`. String values also leave empty strings as they are, and numeric values skip rows
  that already hold the value. If an `UPDATE` fails, the table is emptied again so no production values are left
  behind, and the error is raised with a reminder that many columns are sanitized by default.
- **Read through the client.** Each row is read into Ruby and written as an `INSERT` with the sanitized values in
  place. Every row gets the sanitized value, including rows where the column was `NULL` or empty.

So the same export can produce slightly different data on the two paths. See [Known limitations](limitations.md).
