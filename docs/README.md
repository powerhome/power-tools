# PowerTools

At [Power Home Remodeling](https://powerhrg.com/), we have created foundational bits of code that we use to configure our applications, several of which are [cobra](https://cbra.info/)-based. We have packaged these individually inside a mono-repo to help engineers more easily maintain and consume them among our suite of applications, products and features.

## Packages 📦

power-tools currently contains the following packages (marked for release to rubygems 💎 or npm ☕️):

[api_chai](https://github.com/powerhome/power-tools/blob/main/packages/api_chai/docs/README.md) 💎

ApiChai provides a simple integration with net-http around a lightweight layer for reporting and graceful error handling.

[audit_tracker](https://github.com/powerhome/power-tools/blob/main/packages/audit_tracker/docs/README.md) 💎

AuditTracker helps you centralize data tracking configuration to be used across different models.

[camel_trail](https://github.com/powerhome/power-tools/blob/main/packages/camel_trail/docs/README.md) 💎

CamelTrail makes it easy to keep a history of attribute changes on a model.

[consent](https://github.com/powerhome/power-tools/blob/main/packages/consent/docs/README.md) 💎

Consent provides permission-based authorization.

[cygnet](https://github.com/powerhome/power-tools/blob/main/packages/cygnet/docs/README.md) 💎

Helping ruby developers implement easy patterns.

[data_taster](https://github.com/powerhome/power-tools/blob/main/packages/data_taster/docs/README.md) 💎

Delicious and sanitized data samples for development and testing.

[dep_shield](https://github.com/powerhome/power-tools/blob/main/packages/dep_shield/docs/README.md) 💎

Enable alerts about deprecated features & prevent new ones from being introduced.

[edgestitch](https://github.com/powerhome/power-tools/blob/main/packages/edgestitch/docs/README.md) 💎

Edgestitch allows engines to define partial structure-self.sql files to be stitched into a single structure.sql file by the umbrella application.

[lumberaxe](https://github.com/powerhome/power-tools/blob/main/packages/lumberaxe/docs/README.md) 💎

Lumberaxe handles logging output formatting.

[nitro_config](https://github.com/powerhome/power-tools/blob/main/packages/nitro_config/docs/README.md) 💎

When included in a Rails application, NitroConfig loads the configuration file at `config/config.yml` within the application directory and makes its values available at `NitroConfig.config`. Config values are loaded based on the Rails environment, permitting the specification of multiple environments' configurations in a single file.

[ostruct-sanitizer](https://github.com/powerhome/power-tools/blob/main/packages/ostruct-sanitizer/docs/README.md) 💎

Rails-like sanitization hooks to be applied to OpenStruct fields.

[@powerhome/eslint-config](https://github.com/powerhome/power-tools/blob/main/packages/eslint-config/docs/README.md) ☕️

Shared eslint-config and Prettier formatting from Power Home Remodeling.

[rabbet](https://github.com/powerhome/power-tools/blob/main/packages/rabbet/docs/README.md) 💎

A shared layout so that your suite of applications can have the same look and feel.

[rubocop-cobra](https://github.com/powerhome/power-tools/blob/main/packages/rubocop-cobra/docs/README.md) 💎

This gem is focused on providing Cops to support a healthy cobra app development. See more in [`rubocop-cobra`](../packages/rubocop-cobra).

[rubocop-powerhome](https://github.com/powerhome/power-tools/blob/main/packages/rubocop-powerhome/docs/README.md) 💎

This gem is focused on providing standard rubocop configuration for Power Home Remodeling ruby apps. See more in [`rubocop-powerhome`](../packages/rubocop-powerhome).

## Installation 🛠

These packages are all meant to install inside of an application and aren't intended to stand alone; currently, they are all published to [RubyGems](https://rubygems.org/) or [npm](https://www.npmjs.com/) and you can use standard methods to install them.

For ruby gems:
```ruby=
# Gemfile

gem "nitro_config"
```

For JS modules:
```js
# package.json

"devDependencies": {
  "@powerhome/eslint-config": "0.1.0"
}
```

## Local Development 👩🏽‍💻

If a change needs to be made to a package, the easiest way to develop and test locally would be to temporarily change your Gemfile to point to your local version of the package:

```ruby=
# Gemfile

gem "nitro_config", path: "~/path/to/gems/nitro_config"
```

For JS modules you can point your package.json to the local version of the package:
```js
# package.json
"devDependencies": {
  "@powerhome/eslint-config": "file:../path/to/eslint-config"
}
```

⚠️ <b>Please note</b> that such a change should never be committed, as other users would not have access to the same path your computer. ⚠️

## Testing 🔍

The expectation for these packages is that additions/modifications should be covered in the specs.

UI testing will be done by opening a PR/branch, and then opening a PR for a client application that points to the version on the corresponding branch.

```ruby=
# Gemfile

gem "nitro_config", git: "https://github.com/powerhome/power-tools", glob: "packages/nitro_config/nitro_config.gemspec", branch: "example-branch"
```

For JS modules you will need to use gitpkg.now.sh to point to a subfolder within a repository since NPM/Yarn doesn't support subfolder packages yet. Add to your package.json:
```js
"@powerhome/eslint-config": "https://gitpkg.now.sh/powerhome/power-tools/packages/eslint-config?<branch-name>",
```


## Release 🚀

Releases will be published according to [Semantic Versioning](https://semver.org/) and it is the responsibility of the consumers to keep their application dependencies up to date. We recommend leveraging [renovatebot](https://github.com/renovatebot/renovate) 🤖

## Supporting multiple gem versions

To support multiple versions of a gem, and add a build to the pipeline, we use [Appraisal](https://github.com/thoughtbot/appraisal). The installation is simple, add `appraisal` to your gemspec as a development dependency and install it, then create an Appraisals file like the following to support multiple versions of rails:

```ruby
appraise "rails-6-1" do
  gem "rails", "6.1.7.7"
end

appraise "rails-7-0" do
  gem "rails", "7.0.8.1"
end
```

Run `bundle exec appraisal install`, which will:

1. Create a `gemfiles` directory
1. Create a different `Gemfile` for each appraisal
1. Install each `Gemfile` bundler and generate a lock file

The generated file often doesn't comply with `rubocop` defined rules, so you'll also want to run `bundle exec rubocop -A gemfiles`.

Commit everything that was generated and you can now configure your github workflow. Add the gemfiles to the workflow arguments and they should run with each of the supported ruby versions. [`edgestitch`s workflow](.github/workflows/edgestitch.yml) is a good example.

When updating gems it's important to remember to run `bundle exec appraisal bundle update <gem>`, so all your lock files are updated, but CI will remember you otherwise.

To run *any* command targeting each of the Appraisals, just run `bundle exec appraisal <command>`, for further information on Appraisal refer to [their documentation](https://github.com/thoughtbot/appraisal).

## Maintenance 🚧

These packages are maintained by [Power's](https://github.com/powerhome) Heroes for Hire team.

## Contributing 💙

Contributions are welcome! Feel free to [open a ticket](https://github.com/powerhome/power-tools/issues/new) or a [PR](https://github.com/powerhome/power-tools/pulls).
