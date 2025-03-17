# Contributing

## Adding a new Power Tool

Every package should:

* [ ] be a library maintained by employees/teams of Power Home Remodeling. The employee/team that publishes the gem is responsible for addressing any issues, bugs, and keeping the dependencies up-to-date
* [ ] be open-sourced and available to the community for free, and we should ensure that any code added to this repository has been cleared with management so we're not infringing on Power's intellectual property.
* [ ] have an entry in power-tool's [readme](./README.md), listed alphabetically and annotated as outlined there.
* [ ] have it's own readme with specific installation and usage guidelines.
* [ ] be accurately [registered in the Portal catalog](../portal.yml)
* [ ] [include a mkdocs.yml file](https://portal.powerapp.cloud/docs/default/system/portal/user-guide/distributing-documentation/)
* [ ] have a CI workflow set up in `.github/workflows/your-package.yml`
* [ ] use [Semantic Versioning](https://semver.org/) -- any packages that are currently only used in a single repository are considered to be experimental until they can be verified in a second repo
* [ ] be versioned, with its own constant `packages/yourpackage/lib/yourpackage/version.rb`
* [ ] track its versioned changes with a changelog
* [ ] include proper testing, both automated and manual. See [Testing](./README.md#testing-) for more

Additional, ruby gems should have:

* [ ] defined a required_ruby_version in their gemspec
* [ ] set up linting via `rubocop-powerhome`; it is expected that all violations are addressed
* [ ] validated licenses with [license_finder](https://github.com/pivotal/LicenseFinder)
* [ ] managed Ruby/Rails and/or other fundamental package versions through [appraisal](https://github.com/thoughtbot/appraisal)

## Publishing your tool

* update your package version and add any changes to your changelog
* get your PR merged to the main branch
* [create a new release](https://github.com/powerhome/power-tools/releases/new) with a tag in this format (where the new version is 1.1.1): `v1.1.1-mygemname`. The release title can match the tag, and the description should include the changes being released in this version.
* checking "set as the latest release" and clicking "Publish Release" should kick off a Github Action that will push your package to your package hosting service
