# Wayfinding

Cross-application URL resolution.

Wayfinding is a global registry of named destinations. It lets one component link to a route owned by
another without depending on that component.

Links are not functionality. No component should acquire a dependency because it renders an anchor tag.

## Why

Without a registry, a component that links to another component's page must reach into that engine's
`url_helpers`, depend on the owner just for the link, or hardcode the path. Each option couples the caller
to the route's current owner or location; a hardcoded path can also break silently.

Wayfinding gives one accessor and one registration. Moving a route becomes a one-line change to the
registration; every call site is untouched.

## Registering

Registration is configuration: every argument is a keyword, so order does not matter. Register from an
initializer.

```ruby
Wayfinding.register(
  name: :home,
  engine: -> { Homes::Engine },
  helper: :home_path
)
```

`engine:` accepts a lambda or the constant. Prefer the lambda so the engine is resolved lazily.

`helper:` is the common form. Wayfinding derives the corresponding `_url` helper for `url_for`.

For anything that is not a bare helper call, pass a block. Within the block, `self` is the engine's
`url_helpers` object. That lets the resolver call `results_path(...)` directly instead of repeating
`Search::Engine.routes.url_helpers.results_path(...)`.

```ruby
Wayfinding.register(name: :search_results, engine: -> { Search::Engine }) do |query|
  results_path(q: query)
end
```

For `url_for`, calls ending in `_path` inside an engine-backed block are mapped to the corresponding
`_url` helper. Wayfinding cannot convert an arbitrary path string after the block returns, so a block
that supports both lookup forms must build its result from route helpers rather than hardcoding a path.

Omit `engine:` for a destination that is not a Rails route. Wayfinding calls the block directly, and
`path_for` and `url_for` both return its result.

## Looking up

```ruby
Wayfinding.path_for(:home, home, tab: "activity")
# => "/homes/17?tab=activity"

Wayfinding.url_for(:home, home)
# => "https://example.com/homes/17"
```

Looking up an unregistered destination raises `Wayfinding::UnregisteredDestination`, listing what is
registered. There is no null object and no production fallback: a missing registration is a boot-state
bug, not a runtime condition.

## Kinds

A kind is a named field contract. Applications define kinds; Wayfinding only enforces them.

```ruby
Wayfinding.define_kind(:report, requires: %i[label description action subject])

Wayfinding.register(
  name: :activity_report,
  kind: :report,
  engine: -> { Reports::Engine },
  helper: :activity_reports_path,
  action: :view_activity_report,
  subject: -> { Account },
  label: "Activity Report",
  description: "Summarizes recent account activity"
)

Wayfinding.of_kind(:report).accessible_by(current_ability)
```

A destination without a kind is still resolvable by `path_for`, but is invisible to `of_kind`. Declaring
a kind does not remove point lookup, so `path_for(:activity_report)` still works.

`requires:` may name any field. Validation asserts presence only and never resolves callables, so a
lazily registered `subject: -> { Account }` passes without autoloading the model.

### Destination metadata

Every keyword other than the routing structure is application metadata. Wayfinding does not give fields
such as `label` or `description` special behavior. Metadata is stored without interpretation and read
with `#[]`:

```ruby
destination = Wayfinding.fetch(:activity_report)
destination[:label]
destination[:data]
```

Resolve any callable field lazily with `#value_for`:

```ruby
destination.value_for(:subject)
```

`action` and `subject` are metadata with one additional invariant: if either is supplied, both must be.
`accessible_by(ability)` reads that pair and calls `ability.can?(action, subject)`. Display policy, such as
falling back from a missing description to a label, belongs to the consuming application.

## Verifying

Assert at boot that every expected destination is registered, so a dropped registration fails the boot
rather than rendering a broken link.

```ruby
Wayfinding.verify!(%i[home activity_report])
```

## Testing

```ruby
require "wayfinding/rspec"
```

Each example runs inside `Wayfinding.preserve!`, so anything registered in a spec is rolled back. Use
`stub_destination` rather than mocking Wayfinding itself.

```ruby
stub_destination(:home, "/homes/1")
stub_destination(:home) { |home| "/homes/#{home.id}" }
```
