# Documentation and workflow

## Write for the public

Open-source gem: docs, specs, comments, commits, examples must make sense to any user.

- Never name/describe internal apps, teams, infrastructure. Use generic examples (`Place`, `places.location`, "an app that ...").
- Migration guide covers every upstream line users may come from (see `drop-in-replacement.md`), not one app's setup. App-specific rollout plans belong in that app's repo.

## Style

README: simple, fun, direct. Short and complete beats thorough and long.

- Say what to do and what changes; the why belongs in comments and commit messages.
- Contrasting with activerecord-mysql2rgeo-adapter's approach is welcome.
- Migration steps and differences: one direct line each, nothing lost, grouped by affected upstream version.
- Prefer examples, lists, tables over paragraphs.

## Docs current in the same commit

- `docs/README.md` (user guide: requirements, installation, usage, configuration, "Migrating from activerecord-mysql2rgeo-adapter"): update with any change to behaviour, options, supported versions or dependencies.
- `docs/CHANGELOG.md`: entry under `## [Unreleased]` per user-visible change, written for users ("Spatial columns load as RGeo objects on trilogy"), not a commit log.
- Public Ruby API has doc comments; private seams link the Rails source they depend on (see `design.md`).
- Repo-level entries (root `docs/README.md`, `portal.yml`) change when the package's description or status changes.

## Build

- `bundle exec rake` = all of CI: `rake spec` (gem specs on trilogy + mysql2), `rake regression` (AR test suite on both drivers with gem loaded), RuboCop. Must pass before every commit.
- CI: `.github/workflows/activerecord-mysql-rgeo.yml` via shared `powerhome/github-actions-workflows` ruby-gem workflow, for every appraisal and Ruby version listed there. Adding/dropping a Rails or Ruby version updates `Appraisals`, `gemfiles/`, the workflow and README together.

## Commits

- Small, incremental, each green: one behaviour + its specs + docs.
- Imperative subject <~70 chars, then a body explaining why.
- Release: bump `ActiveRecord::MysqlRgeo::VERSION` (SemVer), move CHANGELOG entries under the new version, tag `v<version>-activerecord-mysql-rgeo`.
