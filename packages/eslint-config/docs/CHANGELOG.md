# Changelog

## Unreleased

- Add Yarn resolutions for various eslint dependencies to address CVEs
  - [Dependabot #864](https://github.com/powerhome/power-tools/security/dependabot/864)
  - [Dependabot #1169](https://github.com/powerhome/power-tools/security/dependabot/1169)
  - [Dependabot #862](https://github.com/powerhome/power-tools/security/dependabot/862)
  - [Dependabot #861](https://github.com/powerhome/power-tools/security/dependabot/861)
  - [Dependabot #803](https://github.com/powerhome/power-tools/security/dependabot/803)
  - [Dependabot #1168](https://github.com/powerhome/power-tools/security/dependabot/1168)
  - [Dependabot #971](https://github.com/powerhome/power-tools/security/dependabot/971)
  - [Dependabot #797](https://github.com/powerhome/power-tools/security/dependabot/797)

## [0.3.1](https://github.com/powerhome/power-tools/compare/eslint-config/v0.3.0...eslint-config/v0.3.1) (2026-11-23)


### Fixed

* **deps:** Update dependency @babel/core to v7.29.6 [SECURITY] ([#451](https://github.com/powerhome/power-tools/issues/451)) ([d42f9e3](https://github.com/powerhome/power-tools/commit/d42f9e3802b603a2a232571ef9d065827a39cde0))
* **deps:** update minimatch to v11 [SECURITY] ([#467](https://github.com/powerhome/power-tools/issues/467)) ([d3791a5](https://github.com/powerhome/power-tools/commit/d3791a56b7866a424bcabc234b66326e613b2c97))

## [0.2.2] - 2026-01-14

- Bump many dependencies

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
