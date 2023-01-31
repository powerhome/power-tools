## Unreleased

## [0.2.2] - 2023-01-31

- NPM doesn't allow symlinks [#92](https://github.com/powerhome/power-tools/pull/92) let's see if it will copy a file to the root while publishing

## [0.2.1] - 2023-01-31

- Add readme to NPM [#90](https://github.com/powerhome/power-tools/pull/90)

NPM packages require a README file at the root level of the package: https://docs.npmjs.com/about-package-readme-files

This PR attempts to display the existing docs/README file through a symlink. If that doesn't work, it's possible to add a script to the publishing process to copy over the file.

## [0.2.0] - 2023-01-30

- Add prettier configuration [#71](https://github.com/powerhome/power-tools/pull/71)
- Minor version upgrades from dependabot
  - [#33](https://github.com/powerhome/power-tools/pull/33)
  - [#37](https://github.com/powerhome/power-tools/pull/37)
  - [#39](https://github.com/powerhome/power-tools/pull/39)
  - [#43](https://github.com/powerhome/power-tools/pull/43)
  - [#47](https://github.com/powerhome/power-tools/pull/47)
  - [#50](https://github.com/powerhome/power-tools/pull/50)

## [0.1.0] - 2022-10-26

- Migrates existing functionality from power-linting [#30](https://github.com/powerhome/power-tools/pull/30)
