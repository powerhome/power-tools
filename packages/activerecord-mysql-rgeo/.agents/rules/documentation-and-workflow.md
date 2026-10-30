# Documentation and workflow

## Write for the public

This is an open-source gem. Docs, specs, code comments, commit messages and
examples must make sense to anyone using it:

- Don't name or describe internal applications, teams or infrastructure. Use
  generic examples (`Place`, `places.location`, "an app that ...").
- The migration guide covers every upstream line people may be coming from
  (see `drop-in-replacement.md`), not one application's setup. App-specific
  rollout plans belong in that application's repository.

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

- `bundle exec rake` is the whole CI: `rake spec` (the gem's specs on trilogy
  and mysql2), `rake regression` (Active Record's test suite on both drivers,
  with the gem loaded), then RuboCop. It must pass before every commit.
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
