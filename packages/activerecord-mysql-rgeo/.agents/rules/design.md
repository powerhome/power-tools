# Design: extend Rails, don't replace it

Adds spatial support to Active Record's own MySQL adapters. Not an adapter; keep it that way.

## Hard constraints

- **No driver dependency.** Never `require "trilogy"`/`"mysql2"` or reference `::Trilogy`, `::Mysql2`, `TrilogyAdapter`, `Mysql2Adapter` at load time. Shared behaviour goes on `AbstractMysqlAdapter`; driver-specific wiring only in `ActiveSupport.on_load(:active_record_trilogyadapter)` / `:active_record_mysql2adapter`. Enforced by `spec/active_record/mysql_rgeo_spec.rb`.
- **Order-independent loading.** Must work required before or after AR loads the driver adapter: use `ActiveSupport.on_load`, not require-time patches.
- **One place for patches.** Change Rails classes only via `prepend`/`include`, all calls in `lib/active_record/mysql_rgeo.rb` (or a file it delegates to). No reopening Rails classes elsewhere.
- **Always call `super`.** Overrides handle the spatial case, else return `super` unchanged. Non-spatial columns/types/SQL behave exactly as plain Rails; other gems (e.g. departure) and apps prepend into the same classes.
- **Global but small.** The gem affects every MySQL connection, so patches act only on spatial data (spatial column types, RGeo values, spatial index options).

## SOLID

- **SRP:** one module per concern (type map, quoting, schema statements, schema creation, column definitions, Arel visitor, column metadata). Needs "and" to describe → split.
- **Open/closed:** extend via Rails seams (load hooks, `prepend`, type map registration). Never copy a Rails method body to change one line; if unavoidable, isolate it, link the mirrored Rails source, and spec it on every appraisal.
- **Liskov:** a patched `TrilogyAdapter` passes anything a plain one does. Spatial columns subclass `MySQL::Column` and keep its interface.
- **ISP:** modules depend only on adapter methods they call. Don't touch Rails objects' ivars; `instance_variable_set` → find public API or document why.
- **DIP:** shared code asks the connection (or a small `ActiveRecord::MysqlRgeo` config object) for things like default SRID; never names a concrete adapter class.

## Private Rails APIs

Private seams (`type_map`, `new_column_from_field`, `schema_creation`, `arel_visitor`) only when no public seam exists. Then:

- Comment linking the Rails source for the oldest supported version.
- Specs must fail on every appraisal if the signature changes.
- Handle version differences in one small named branch (e.g. `COLUMN_TAKES_CAST_TYPE`), not scattered `if`s.
