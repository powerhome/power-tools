# Wayfinding

Cross-application URL resolution.

Wayfinding is a global registry of named destinations. Any component can link to any page without
declaring a dependency on the component that owns the route.

Links are not functionality. No component should acquire a dependency because it renders an anchor tag.

## Why

Without a registry, a component that wants to link to another component's page has three bad options:
reach into that engine's `url_helpers` directly, depend on the owning component just for the link, or
hardcode the path. All three make the URL's owner unable to move it, and the third breaks silently.

Wayfinding gives one accessor and one registration. Moving a route becomes a one-line change to the
registration; every call site is untouched.

## Registering

Registration is configuration, so every argument is a keyword and order never matters. Register from an
initializer.

```ruby
Wayfinding.register(
  name: :home,
  engine: -> { Homes::Engine },
  helper: :home_path
)
```

`engine:` accepts a lambda or the constant. Prefer the lambda so the engine is resolved lazily.

`helper:` is the common form. Wayfinding derives the `_url` variant from it, so `url_for` costs nothing.

For anything that isn't a bare helper call, pass a block. It is `instance_exec`'d against the engine's
`url_helpers`, so it never repeats the engine prefix.

```ruby
Wayfinding.register(name: :lead_source, engine: -> { EstimateAppointments::Engine }) do |lead_source|
  lead_source_path(lead_source)
end
```

`url_for` evaluates an engine-backed block with calls ending in `_path` mapped to the corresponding
`_url` helper. Arbitrary strings cannot be converted, so a block that needs both lookup forms must build
its result from route helpers rather than hardcoding a path.

Omit `engine:` and the block is called plainly, for destinations that are not Rails routes at all.

## Looking up

```ruby
Wayfinding.path_for(:home, home, current_tab: "Projects")
# => "/homes/17?current_tab=Projects"

Wayfinding.url_for(:home, home)
# => "https://base.com/homes/17"
```

Looking up an unregistered destination raises `Wayfinding::UnregisteredDestination`, listing what is
registered. There is no null object and no production fallback: a missing registration is a boot-state
bug, not a runtime condition.

## Kinds

A kind is a named field contract. Applications define kinds; Wayfinding only enforces them.

```ruby
Wayfinding.define_kind(:report, requires: %i[label description action subject])

Wayfinding.register(
  name: :installer_pay_report,
  kind: :report,
  engine: -> { Installations::Engine },
  helper: :installer_pay_reports_path,
  action: :view_installer_pay_report,
  subject: -> { InstallTask },
  label: "Installer Pay Report",
  description: "Breaks down Materials, Equipment, and Labor to pay installers"
)

Wayfinding.of_kind(:report).accessible_by(current_ability)
```

A destination with no kind is just a path: resolvable by `path_for`, invisible to `of_kind`. Declaring a
kind does not remove point lookup, so `path_for(:installer_pay_report)` still works.

`requires:` may name any field. Validation asserts presence only and never resolves callables, so a
lazily registered `subject: -> { InstallTask }` passes without autoloading the model.

### Destination metadata

Every keyword other than the routing structure is application metadata. It is stored without
interpretation and read with `#[]`:

```ruby
destination = Wayfinding.fetch(:installer_pay_report)
destination[:label]
destination[:data]
```

Resolve any callable field lazily with `#value_for`:

```ruby
destination.value_for(:label)
```

`action` and `subject` are metadata with one additional invariant: if either is supplied, both must be.
`accessible_by(ability)` reads that pair and calls `ability.can?(action, subject)`. Display policy, such as
falling back from a missing description to a label, belongs to the consuming application.

## Verifying

Assert at boot that every expected destination is registered, so a dropped registration fails the boot
rather than rendering a broken link.

```ruby
Wayfinding.verify!(%i[home installer_pay_report])
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
