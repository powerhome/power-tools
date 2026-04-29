# TwoPercent [![Build Status](https://travis-ci.org/powerhome/two_percent.svg?branch=master)](https://travis-ci.org/powerhome/two_percent)

## What is TwoPercent

TwoPercent is a SCIM 2.0 (System for Cross-domain Identity Management) Rails Engine that handles identity provisioning from external Identity Providers (IdPs). It provides endpoints for creating, updating, and deleting Users and Groups, and publishes domain events when resources change.

## SCIM 2.0 Compliance

**Implemented (Partial RFC 7644 Protocol Compliance):**
- ✅ POST (Create) for Users and Groups
- ✅ PUT (Replace) for Users and Groups
- ✅ PATCH (Partial Update) with Operations array
- ✅ DELETE for Users and Groups
- ✅ Bulk operations (bulkId references, continue-on-error)
- ✅ RFC 7644 Section 3.12 error responses with scimType
- ✅ Extension schema support

**Not Yet Implemented:**
- ❌ GET (Single resource retrieval)
- ❌ GET with filtering, pagination, sorting (List operations)
- ❌ ETag support for concurrency control
- ❌ Discovery endpoints (RFC 7642): /ServiceProviderConfig, /ResourceTypes, /Schemas
- ❌ Full RFC 7643 schema validation

**Note:** The current release prioritizes write operations required for IdP provisioning. Read operations, filtering, and discovery endpoints are not yet implemented but are on the roadmap for future releases.

## Architecture

TwoPercent is designed as a standalone gem that can be mounted in a parent Rails application:

```
Parent Rails Application
├── Mounts TwoPercent::Engine → /scim
├── Mounts other engines as needed
└── Subscribes to TwoPercent domain events

    ↓ TwoPercent publishes domain events

    → Your application subscribes to events
    → Your application queries ScimUser/ScimGroup models
    → Integration via events or direct model access
```

**Key Principle**: Mount TwoPercent in your parent application and integrate via domain events or direct model queries.

## Installation

Add to your application with bundle

```ruby
bundle add two_percent
```

Run the install generator:

```bash
rails generate two_percent:install
rails db:migrate
```

Mount the engine in your parent application's `config/routes.rb`:

```ruby
mount TwoPercent::Engine => "/scim"
```

Configure authentication in `config/initializers/two_percent.rb`.

## Event subscription

Use [AetherObservatory](https://github.com/powerhome/power-tools/blob/main/packages/aether_observatory/docs/README.md#stopping-observers) observers to subscribe to `two_percent.*` events:

| Event Name  | Description | Arguments |
| - | - | - |
| `"create.all"` | Any resource is being created | resource: String, params: SCIM hash |
| `"create.#{resource}"`, i.e.: `"create.Users"` | A #{resource} is being created | resource: String, params: SCIM hash |
| `"update.all"` | Any resource is being updated | resource: String, params: SCIM hash |
| `"update.#{resource}"`, i.e.: `"update.Users"` | A #{resource} is being updated | resource: String, id: String, params: SCIM hash |
| `"replace.all"` | Any resource is being replaced completely | resource: String, params: SCIM hash |
| `"replace.#{resource}"`, i.e.: `"replace.Users"` | A #{resource} is being replaced completely | resource: String, id: String, params: SCIM hash |
| `"delete.all"` | Any resource is being deleted | resource: String, params: SCIM hash |
| `"delete.#{resource}"`, i.e.: `"delete.Users"` | A #{resource} is being deleted | resource: String, id: String |

## Authenticating SCIM requests

Most of the applications will want to secure the requests to SCIM. This can be done using the `authenticate` configuration:

I.e.:

```ruby
TwoPercent.configure do |config|
  config.authenticate = ->(*) do
    authenticate_with_http_token do |token|
      Token.active.find_by!(token:)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/two_percent.
