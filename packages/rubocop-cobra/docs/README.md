# Rubocop::Cobra

This gem is focused on providing Cops to support a healthy cobra app development (see https://cbra.info and https://github.com/powerhome/cobra_commander).

## Installation

Add this line to your application's Gemfile under development:

```ruby
gem "rubocop-cobra", require: false
```

And then execute:

    $ bundle install

## Usage

Add the plugin to your `.rubocop.yml`:

```yml
plugins:
  - rubocop-cobra
```

rubocop-cobra is a [RuboCop plugin](https://docs.rubocop.org/rubocop/plugin_migration_guide.html), so it needs RuboCop 1.72 or newer. Listing it under `require:` still works but RuboCop prints a deprecation warning.

That's it! You can override the standard configuration after that.

### Deprecating a constant

`Cobra/DeprecatedConstant` flags references to constants your application has deprecated, such as a class left behind as a shim after it moved into another component. It does nothing until you list each deprecated constant and its replacement:

```yml
Cobra/DeprecatedConstant:
  Constants:
    Territory: Directory::Territory
    UserTitle: Directory::Title
```

It flags constant references, `class_name:` and `constantize` strings, and associations whose class Rails infers from the name (`belongs_to :territory`), and autocorrects each to the replacement. The autocorrect is unsafe, so it only runs with `rubocop -A`: until the deprecated class is a bare shim (`class Territory < Directory::Territory; end`), it may still carry behavior the replacement lacks. It skips references that Ruby or Rails already resolve to the replacement, such as `Territory` inside `module Directory`, and the deprecated class's own definition. Remove an entry once its constant is deleted.

To roll it out gradually, disable it in the components that still own the deprecated constants:

```yml
# components/core_models/.rubocop.yml
Cobra/DeprecatedConstant:
  Enabled: false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power_linting/rubocop-cobra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
