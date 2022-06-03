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

Add a `require` line to your `.rubocop.yml`:

```yml
require:
  - rubocop-cobra
```

That's it! You can override the standard configuration after that.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power_linting/rubocop-cobra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
