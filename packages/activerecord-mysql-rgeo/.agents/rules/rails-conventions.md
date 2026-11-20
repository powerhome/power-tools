# Ruby and Rails conventions

Code should look at home in Rails' `activerecord/lib`.

## Layout and naming

- `lib/active_record/mysql_rgeo/...` holds `ActiveRecord::MysqlRgeo`; one constant per file, path matches constant (Zeitwerk naming, though the gem requires explicitly). `lib/activerecord-mysql-rgeo.rb` only requires `active_record/mysql_rgeo`.
- Rails vocabulary: `sql_type`, `cast_type`, `type_map`, `SchemaCreation`, `TableDefinition`, `ColumnMethods`, `SchemaStatements`. Match names and signatures of the Rails methods extended.
- `ActiveSupport::Concern` for modules with `included`/`class_methods`; plain modules for plain `prepend`s.
- Internals get `# :nodoc:` as in Rails. Public API (column methods, `Type::Spatial`, configuration) gets YARD/RDoc comments.

## Ruby style

- `# frozen_string_literal: true` in every Ruby file.
- RuboCop (`rubocop-powerhome`) passes. Fix offenses, don't disable; if unavoidable, scope narrowly in `.rubocop.yml` with a comment saying why.
- Small methods, guard clauses, keyword args. No `method_missing`; no `send` to private methods of Rails objects unless a documented private seam (see `design.md`).
- Raise specific errors (`ArgumentError`, `ActiveRecord::ActiveRecordError` subclasses) with messages saying what to do.

## Rails behaviours

- Rails-style config: `ActiveRecord::MysqlRgeo.configure` or `config.active_record.*`-like accessors, plus `database.yml` keys where connection-related.
- Deprecate before removing: gem-specific `ActiveSupport::Deprecation.new(next_major, "activerecord-mysql-rgeo")`, registered with `Rails.application.deprecators` when Rails is present.
- Use `ActiveSupport.on_load`; never force-load AR components early.
- Support AR 7.2 through edge. Branch on `ActiveRecord.gem_version` in one named constant; never on `RUBY_VERSION` or `respond_to?` guesses.

## Dependencies

- Runtime: only `activerecord` and `rgeo-activerecord`. Anything else needs a strong reason and a README requirements update.
- Dev deps in `Gemfile`; keep all appraisal lockfiles in sync via `bundle exec appraisal install`, including the `x86_64-linux` platform.
