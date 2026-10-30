# Ruby and Rails conventions

Write code that would look at home inside Rails' own `activerecord/lib`.

## Layout and naming

- Follow Rails' layout: `lib/active_record/mysql_rgeo/...` holds the
  `ActiveRecord::MysqlRgeo` namespace, one constant per file, with the file path
  matching the constant (Zeitwerk naming, even though the gem requires
  explicitly). `lib/activerecord-mysql-rgeo.rb` only requires
  `active_record/mysql_rgeo`.
- Use Rails' vocabulary: `sql_type`, `cast_type`, `type_map`, `SchemaCreation`,
  `TableDefinition`, `ColumnMethods`, `SchemaStatements`. Match the method names
  and signatures of the Rails methods being extended.
- Use `ActiveSupport::Concern` for modules with `included` /
  `class_methods` blocks. Plain modules for plain `prepend`s.
- Hide internals with `# :nodoc:` the way Rails does. Public API (column methods,
  `Type::Spatial`, configuration) gets YARD-style or RDoc comments.

## Ruby style

- `# frozen_string_literal: true` in every Ruby file.
- RuboCop (`rubocop-powerhome`) must pass. Fix offenses rather than disabling
  them. If a cop must be disabled, scope it narrowly in `.rubocop.yml` and say
  why in a comment.
- Prefer small methods, guard clauses and keyword arguments. No
  `method_missing`, no `send` to private methods of Rails objects unless it is
  documented as a private seam (see `design.md`).
- Raise specific errors (`ArgumentError`, `ActiveRecord::ActiveRecordError`
  subclasses) with messages that say what to do.

## Rails behaviours to respect

- Configuration is done Rails-style: `ActiveRecord::MysqlRgeo.configure` or
  `config.active_record.*`-like accessors, plus `database.yml` keys where they
  belong to the connection.
- Deprecate before removing: use a gem-specific
  `ActiveSupport::Deprecation.new(next_major, "activerecord-mysql-rgeo")`
  deprecator and register it with `Rails.application.deprecators` when Rails is
  present.
- Use `ActiveSupport.on_load` hooks; never force-load Active Record components
  early.
- Support Active Record 7.2 through edge. Branch on
  `ActiveRecord.gem_version` in one named constant, never on `RUBY_VERSION` or
  `respond_to?` guesses.

## Dependencies

- Runtime: only `activerecord` and `rgeo-activerecord`. Anything else needs a
  strong reason and an update to the README requirements.
- Dev dependencies go in the `Gemfile`; keep all appraisal lockfiles in sync
  with `bundle exec appraisal install`, and include the `x86_64-linux` platform.
