# @powerhome/eslint-config

Provides eslint-config for Power Home Remodeling apps.

## Installation

Add this line to your application's package.json:

```ruby
  "devDependencies": {
    ...
    "@powerhome/eslint-config": "0.1.0",
    ...
  }
```

And then yarn:

    $ yarn

## Usage

Assuming it's a typescript app, add an `extends` line to your `.eslintrc.json`:

```js
{
  ...
  extends: [
    ...
    "@powerhome",
  ],
  ...
}
```

That's it! You can override the standard configuration after that.

## Flow type apps

For flow-based apps, replace `@powerhome` by `@powerhome/eslint-config/flow`. Note that usage of Flow at Power is not recommended, and all projects should migrate to TypeScript; this set of rules is provided only for transitionary purposes and will be removed in future releases.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power_linting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
