# Contributing

## Adding a new Power Tool

Every package should:

* [ ] be a library maintained by employees/teams of Power Home Remodeling. The employee/team that publishes the gem is responsible for addressing any issues, bugs, and keeping the dependencies up-to-date
* [ ] be open-sourced and available to the community for free, and we should ensure that any code added to this repository has been cleared with management so we're not infringing on Power's intellectual property.
* [ ] have an entry in power-tool's [readme](./README.md), listed alphabetically and annotated as outlined there.
* [ ] have its own readme with specific installation and usage guidelines.
* [ ] be accurately [registered in the Portal catalog](../portal.yml)
* [ ] [include a mkdocs.yml file](https://portal.powerapp.cloud/docs/default/system/portal/user-guide/distributing-documentation/)
* [ ] have a CI workflow set up in `.github/workflows/your-package.yml`
* [ ] use [Semantic Versioning](https://semver.org/) -- any packages that are currently only used in a single repository are considered to be experimental until they can be verified in a second repo
* [ ] be versioned, with its own constant (`packages/yourpackage/lib/yourpackage/version.rb` for ruby gems)
* [ ] track its versioned changes with a changelog that starts with a `# Changelog` title
* [ ] be registered in [`release-please-config.json`](../release-please-config.json), with its current version in [`.release-please-manifest.json`](../.release-please-manifest.json). The package's folder, workflow and gem names must match, since the release tag is built from the folder name
* [ ] include proper testing, both automated and manual. See [Testing](./README.md#testing-) for more
* [ ] commit all lockfiles, including yarn.lock, gemfile.lock and/or any appraisal-based lockfiles

Additional, ruby gems should have:

* [ ] defined a required_ruby_version in their gemspec
* [ ] set up linting via `rubocop-powerhome`; it is expected that all violations are addressed
* [ ] validated licenses with [license_finder](https://github.com/pivotal/LicenseFinder)
* [ ] managed Ruby/Rails and/or other fundamental package versions through [appraisal](./README.md#supporting-multiple-gem-versions)

## Publishing your tool

Releases are prepared by [release-please](https://github.com/googleapis/release-please) from the titles of the PRs merged to `main`. PRs are squash-merged, so the PR title is what counts.

* Title your PR as a [Conventional Commit](https://www.conventionalcommits.org/). `fix: ...` releases a patch, `feat: ...` a minor version, and `feat!: ...` a major one. `chore`, `ci`, `docs`, `refactor`, `test` and the other types release nothing. A scope such as `fix(consent): ...` is optional, since release-please finds the package from the files the PR changes. A ticket id can go at the end: `fix(data_conduit): accept sequel 6 [ORA-2386]`.
* A PR that changes several packages releases each of them with its title's type, even if it only touches their lockfiles or RuboCop config. Title changes that are mechanical for most packages as `chore: ...`, or split out the packages whose users see the change.
* Don't bump the version or edit the changelog in your PR. The title becomes the changelog entry, so write it for the package's users.
* Once your PR is merged, release-please opens or updates a release PR for each package it changed, titled `chore(main): release <package> <version>`. It bumps the version, pins it in the package's lockfiles and those of the packages that load it by path, and adds the changelog entry.
* Merging the release PR tags `<package>/v<version>` and creates the GitHub Release. The tag's push runs the package's workflow, which publishes it to RubyGems or npm.

A tag in the old `v<version>-<package>` format still publishes, but release-please won't know about that release: update the package's version in `.release-please-manifest.json` in the same PR that bumps it.
