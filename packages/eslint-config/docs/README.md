# @powerhome/eslint-config

Provides eslint-config and Prettier formatting for Power Home Remodeling apps.

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

## Flow type apps

For flow-based apps, replace `@powerhome` by `@powerhome/eslint-config/flow`. Note that usage of Flow at Power is not recommended, and all projects should migrate to TypeScript; this set of rules is provided only for transitionary purposes and will be removed in future releases.

## Prettier

Prettier takes code formatting decisions while ESlint cares about code quality measurements. Both tools were put together into the same package since they both handle code quality in JS.

To install Prettier rules into your application simply add the following line to your `package.json` and Power's standards for code formatting will be loaded when you run Prettier.

```json
"prettier": "@powerhome/eslint-config/prettier"
```

Prettier and ESlint rules might conflict sometimes. To find out rules that are conflicting you can run the following command line in your project:

```
yarn eslint-config-prettier path/to/main.js
```

That's a helper method created by the `eslint-config-prettier` package that points out which rules are conflicting.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power_linting.

## License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
