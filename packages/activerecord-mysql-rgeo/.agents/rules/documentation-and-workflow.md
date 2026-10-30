# Documentation and workflow

## Keep the docs current in the same commit

- `docs/README.md` is the user guide: requirements, installation, usage,
  configuration, and "Migrating from activerecord-mysql2rgeo-adapter". Any
  change to behaviour, options, supported versions or dependencies updates it in
  the same commit.
- `docs/CHANGELOG.md` gets an entry under `## [Unreleased]` for every
  user-visible change, written for users ("Spatial columns load as RGeo objects
  on trilogy"), not as a commit log.
- Public Ruby API has doc comments; private seams have a comment linking the
  Rails source they depend on (see `design.md`).
- Repo-level entries (`docs/README.md` at the repo root, `portal.yml`) change
  when the package's description or status changes.

## Build

- `bundle exec rake` is the whole CI: specs on trilogy, specs on mysql2, then
  RuboCop. It must pass before every commit.
- CI runs `.github/workflows/activerecord-mysql-rgeo.yml` through the shared
  `powerhome/github-actions-workflows` ruby-gem workflow, for every appraisal and
  Ruby version listed there. Adding or dropping a Rails or Ruby version means
  updating `Appraisals`, the `gemfiles/`, the workflow and the README together.

## Commits

- Small, incremental commits, each green. A commit is one behaviour plus its
  specs and docs.
- Imperative subject line under ~70 characters, then a body explaining why.
- Release by bumping `ActiveRecord::MysqlRgeo::VERSION` (Semantic Versioning),
  moving the CHANGELOG entries under the new version, and tagging
  `v<version>-activerecord-mysql-rgeo`.
