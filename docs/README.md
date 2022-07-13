# PowerTools

At [Power Home Remodeling](https://powerhrg.com/), we have created foundational bits of code that we use to configure our applications, several of which are [cobra](https://cbra.info/)-based. We have packaged these individually inside a mono-repo to help engineers more easily maintain and consume them among our suite of applications, products and features.

## Packages 📦

power-tools currently contains the following packages (marked for release to rubygems 💎 or npm ☕️):

[nitro_config]() 💎
When included in a Rails application, NitroConfig loads the configuration file at `config/config.yml` within the application directory and makes its values available at `NitroConfig.config`. Config values are loaded based on the Rails environment, permitting the specification of multiple environments' configurations in a single file.

## Installation 🛠

These packages are all meant to install inside of an application and aren't intended to stand alone; currently, they are all published to [RubyGems](https://rubygems.org/) and you can use standard Bundler methods to install them.

```ruby=
# Gemfile

gem "nitro_config"
```

## Local Development 👩🏽‍💻

If a change needs to be made to a package, the easiest way to develop and test locally would be to temporarily change your Gemfile to point to your local version of the package:

```ruby=
# Gemfile

gem "nitro_config", path: "~/path/to/gems/nitro_config"
```

⚠️ <b>Please note</b> that such a change should never be committed, as other users would not have access to the same path your computer. ⚠️

## Testing 🔍

The expectation for these packages is that additions/modifications should be covered in the specs.

UI testing will be done by opening a PR/branch, and then opening a PR for a client application that points to the version on the corresponding branch.

```ruby=
# Gemfile

gem "nitro_config", github: "powerhome/nitro_config", branch: "example-branch-name"
```

## Release 🚀

Releases will be published according to [Semantic Versioning](https://semver.org/) and it is the responsibility of the consumers to keep their application dependencies up to date. We recommend leveraging [renovatebot](https://github.com/renovatebot/renovate) 🤖

## Maintenance 🚧

These packages are maintained by [Power's](https://github.com/powerhome) Heroes for Hire team.

## Contributing 💙

Contributions are welcome! Feel free to [open a ticket]() or a [PR]().
