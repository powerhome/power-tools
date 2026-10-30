# activerecord-mysql-rgeo

Spatial support for Active Record's built-in MySQL adapters, backed by
[RGeo](https://github.com/rgeo/rgeo).

Unlike [activerecord-mysql2rgeo-adapter](https://github.com/stadia/activerecord-mysql2rgeo-adapter),
this gem is not a separate database adapter. It extends the adapters that ship
with Rails, so your application keeps `adapter: trilogy` or `adapter: mysql2`
and gains spatial columns, migrations and queries on the same connection.

> **Status:** under development. The spatial features are being ported from
> activerecord-mysql2rgeo-adapter; this page lists what is available today.

## Requirements

- Ruby 3.3+
- Active Record 7.2, 8.0, 8.1 or edge
- MySQL 8.0 or 8.4 (MariaDB is not supported)
- One MySQL driver: [trilogy](https://github.com/trilogy-libraries/trilogy) or
  [mysql2](https://github.com/brianmario/mysql2). This gem depends on neither;
  keep the one your application already uses.

## Installation

```ruby
# Gemfile
gem "activerecord-mysql-rgeo"
gem "trilogy" # or "mysql2"
```

## Development

The specs need a MySQL server. By default they connect to `root:root@127.0.0.1:3306`,
which matches the MySQL server preinstalled on GitHub's Ubuntu runners. Override
it with `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD` and
`MYSQL_DATABASE`. For example, with Docker:

```sh
docker run -d --name activerecord-mysql-rgeo-mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0
MYSQL_PORT=3307 bundle exec rake
```

`bundle exec rake` runs the whole build:

- `rake spec`: the gem's own specs, once per driver (`spec:trilogy`, `spec:mysql2`).
- `rake regression`: Active Record's own test suite, once per driver
  (`regression:trilogy`, `regression:mysql2`), with this gem loaded. It shows
  the gem leaves non-spatial behaviour exactly as Rails ships it. The tests are
  checked out from the Rails repository into `tmp/rails/` at the tag matching
  the bundled Active Record.
- RuboCop.

`regression/excludes.yml` lists the Active Record tests that are skipped, with
the reason for each. Only tests that also fail without this gem belong there;
run the suite with `REGRESSION_BASELINE=1` to check:

```sh
REGRESSION_BASELINE=1 MYSQL_PORT=3307 bundle exec rake regression:trilogy
```

Each supported Active Record version has an [Appraisal](https://github.com/thoughtbot/appraisal)
gemfile under `gemfiles/`. To run the build against one of them:

```sh
bundle exec appraisal rails-7-2 rake
```

## License

BSD-3-Clause. Portions are derived from activerecord-mysql2rgeo-adapter; see
[LICENSE.txt](../LICENSE.txt).
