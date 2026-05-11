## [Unreleased]

- Update rainbow to v3.x [#372](https://github.com/powerhome/power-tools/pull/372)
- Update yard to 0.9.38 to address [Cross-site Scripting vulnerability](https://github.com/powerhome/power-tools/security/dependabot/544) [#394](https://github.com/powerhome/power-tools/pull/394)
- Drop support for Ruby < 3.3 and Rails < 7.1 [#396](https://github.com/powerhome/power-tools/pull/396)
- Remove more Rails 6.0 config handling
- Standardize all libs to support ruby 3.0, ruby 3.3 x rails 6.1 through rails 7.2 [#359](https://github.com/powerhome/power-tools/pull/359)
- Lock activesupport requirement to ~> 7.0.8
- Setup test environment and add simple specs
- Fix issue reading database config to support Rails 6.0
- Add more specs, including actual run of a dump for default sanitization

## [0.4.3] - 2025-07-28 [Unreleased]

## [0.4.2] - 2025-02-27

- Lower nokogiri requirement to 1.14

## [0.4.1] - 2025-02-27

- Fix date flavor for newer rails versions

## [0.3.0] - 2024-04-25

- Add compatibility for encryption with newer versions of attr_encrypted

## [0.2.0] - 2023-12-24

- Rollout of basic features. See README for details.

## [0.1.0] - 2023-05-30

- Initial release
