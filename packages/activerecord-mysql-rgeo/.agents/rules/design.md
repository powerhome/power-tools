# Design: extend Rails, don't replace it

This gem adds spatial support to Active Record's own MySQL adapters. It is not
an adapter. Keep it that way.

## Hard constraints

- **No driver dependency.** Never `require "trilogy"` or `require "mysql2"`, and
  never reference `::Trilogy`, `::Mysql2`, `TrilogyAdapter` or `Mysql2Adapter`
  at load time. Behaviour common to both drivers goes on `AbstractMysqlAdapter`.
  Driver-specific wiring runs only from the driver's load hook
  (`ActiveSupport.on_load(:active_record_trilogyadapter)` /
  `:active_record_mysql2adapter`). The spec in
  `spec/active_record/mysql_rgeo_spec.rb` enforces this.
- **Order-independent loading.** The gem must work whether it is required before
  or after Active Record loads the driver adapter. Hook into
  `ActiveSupport.on_load` instead of patching at require time.
- **One place for patches.** Rails classes are changed only with
  `Module#prepend` / `include`, and every one of those calls lives in a single
  file (`lib/active_record/mysql_rgeo.rb` or one it delegates to). Reopening a
  Rails class elsewhere is not allowed.
- **Always call `super`.** Overrides decide whether to handle the spatial case;
  otherwise they return `super` unchanged. Non-spatial columns, types and SQL
  must behave exactly as in plain Rails. Other gems (departure, nitro_mysql)
  prepend into the same classes.
- **Keep the effect global but small.** Loading the gem changes every MySQL
  connection in the process, so a patch only acts when it sees spatial data
  (spatial column types, RGeo values, spatial index options).

## SOLID, applied here

- **Single responsibility.** One module per concern: type map, quoting, schema
  statements, schema creation, column definitions, Arel visitor, column
  metadata. A module that needs "and" to describe it should be split.
- **Open/closed.** Extend Rails through its seams (load hooks, `prepend`, type
  map registration). Never copy a Rails method body to change one line; if
  that is the only way, isolate it, link the Rails source it mirrors, and cover
  it with a spec on every appraisal.
- **Liskov.** A patched `TrilogyAdapter` must still pass anything a plain one
  passes. Spatial columns are `MySQL::Column` subclasses and keep its interface.
- **Interface segregation.** Modules depend only on the adapter methods they
  call. Don't reach into instance variables of Rails objects; if
  `instance_variable_set` seems necessary, find the public API or document why.
- **Dependency inversion.** Shared code asks the connection (or a small
  `ActiveRecord::MysqlRgeo` configuration object) for things like the default
  SRID. It never names a concrete adapter class.

## Private Rails APIs

Some seams (`type_map`, `new_column_from_field`, `schema_creation`,
`arel_visitor`) are private. Using them is acceptable only when no public seam
exists. When you use one:

- Add a comment linking the Rails source for the oldest supported version.
- Make sure the specs fail on every appraisal if the signature changes.
- Handle version differences in one small, named branch (for example
  `COLUMN_TAKES_CAST_TYPE`), not scattered `if` checks.
