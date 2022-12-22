# Edgestitch

Edgestitch allows engines to define partial structure-self.sql files to be stitched into a single structure.sql file by the umbrella application. This allows big teams to develop large [Cobra](https://cbra.info) [Applications](https://github.com/powerhome/cobra_commander) without much conflict happening in a single structure.sql file. Instead, each team will more likely update one component or two structure-self.sql files while other teams concerned with other areas of the application will be changing different files.

## Installation

### Umbrella App

Add this line to your application's Gemfile:

```ruby
# Gemfile

gem "edgestitch", require: false
```

And then execute:

    $ bundle install

Then require the railtie in the umbrella's `config/application.rb`:

```ruby
# config/application.rb

require "edgestitch/railtie"
```

If your umbrella app also has migrations or even models, you'll have to also install the engine task to your `Rakefile`:

```ruby
# Rakefile

Edgestitch.define_engine(::My::Application)
```

### Engines

Each internal engine will also have a development dependency on `edgestitch`, and can install it the same way:

```ruby
# crazy.gemspec

spec.add_development_dependency "edgestitch"
```

And then execute:

    $ bundle install

And install the helper tasks:

```ruby
Edgestitch.define_engine(::Crazy::Engine)
```

You'll also have to add the `railtie` to the dummy app (as they're dummy umbrella apps), in case the engine has external database dependencies.

```ruby
# spec/dummy/config/application.rb

require "edgestitch/railtie"
```

## Usage

Edgestitch will enhance the default rails tasks, so nothing special has to be done in order to use it. Once edgestitch is correctly installed things should Just Work™️ as explained in the rails manual, but it will be generating `structure-self.sql` along with `structure.sql` files. **Important**: It's recommended that `structure.sql` files are added to `.gitignore`.

# How does it work

Edgestitch works based on table and migrations ownership. Based on these ownerships, Edgestitch can export a `structure-self.sql` file defining the DDL owned by a specific engine.

The stitching process then takes all loaded engines (assuming the dependency between engines is defined correctly) and assembles a structure.sql file.

## Table and Migration Ownerships

A model is owned by an engine when it inherits from the Engine's ApplicationModel, and thus the table is owned by that engine. A migration is owned by the engine if it is defined within its `db/migrate` directory.

## Extra tables

When an external dependency brings in extra tables (i.e. acts_as_taggable) that are not defined in any `structure-self.sql`. To be part of the ecosystem, the new tables should be owned by the engine adding them. That can be done by adding these tables to `<engine>/db/extra_tables`. It's a simple text file with a list of table names that do not inherit from `<Engine>::AplicationModel`, but are owned by that engine and should be included in its structure-self.sql.

## External Gems

An external gem can also define a `structure-self.sql` file to be adapted in this ecosystem. That can be done using the same approach specified in Installation / Engines.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power-tools.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
