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
┌─────────────────────────────────────────────────────────────┐
│  Parent Rails Application                                    │
│                                                               │
│  ┌──────────────────┐      ┌─────────────────────────┐     │
│  │  Your Domain     │◄─────│  TwoPercent::Syncable   │     │
│  │  Models          │      │  (SCIM → Domain sync)   │     │
│  │  (User, Group)   │      └─────────────────────────┘     │
│  └──────────────────┘               ▲                       │
│           ▲                          │                       │
│           │                  ┌───────┴────────┐             │
│           │                  │  Domain Events │             │
│           │                  │  (UserCreated, │             │
│           │                  │   GroupUpdated,│             │
│           │                  │   etc.)        │             │
│           │                  └────────────────┘             │
│           │                          ▲                       │
│           │                          │                       │
│  ┌────────┴──────────┐      ┌───────┴────────┐             │
│  │  Query SCIM Data  │      │  TwoPercent    │             │
│  │  (ScimUser,       │◄─────│  Engine        │             │
│  │   ScimGroup)      │      │  (/scim)       │             │
│  └───────────────────┘      └────────────────┘             │
│                                      ▲                       │
└──────────────────────────────────────┼───────────────────────┘
                                       │
                                  SCIM IdP
                          (Okta, Azure AD, etc.)
```

**Key Principles:**
- **SCIM as Source of Truth**: Identity data flows one-way from IdP → TwoPercent → Your App
- **Domain Events**: TwoPercent publishes domain events when SCIM resources change
- **Syncable Concern**: Optional helper for syncing SCIM data to your domain models
- **Direct Model Access**: Query `ScimUser` and `ScimGroup` models directly when needed

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

## Integration

TwoPercent provides three ways to integrate SCIM data with your application:

### 1. Domain Events (Recommended)

TwoPercent publishes domain events whenever SCIM resources are created, updated, or deleted. Subscribe to these events to keep your domain models in sync:

**Available Events:**

| Event Class | When Published | Attributes |
|-------------|----------------|------------|
| `TwoPercent::Domain::Events::UserCreated` | SCIM user created | `user_attributes` (Hash), `correlation_id` (String) |
| `TwoPercent::Domain::Events::UserUpdated` | SCIM user updated | `user_attributes` (Hash), `correlation_id` (String) |
| `TwoPercent::Domain::Events::UserDeleted` | SCIM user deleted | `user_id` (String), `correlation_id` (String) |
| `TwoPercent::Domain::Events::GroupCreated` | SCIM group created | `group_attributes` (Hash), `resource_type` (String), `correlation_id` (String) |
| `TwoPercent::Domain::Events::GroupUpdated` | SCIM group updated | `group_attributes` (Hash), `resource_type` (String), `correlation_id` (String) |
| `TwoPercent::Domain::Events::GroupDeleted` | SCIM group deleted | `group_id` (String), `resource_type` (String), `correlation_id` (String) |

**Example: Subscribe to domain events**

```ruby
# app/subscribers/scim_user_subscriber.rb
class ScimUserSubscriber
  def self.call(event)
    case event
    when TwoPercent::Domain::Events::UserCreated
      handle_user_created(event)
    when TwoPercent::Domain::Events::UserUpdated
      handle_user_updated(event)
    when TwoPercent::Domain::Events::UserDeleted
      handle_user_deleted(event)
    end
  end

  def self.handle_user_created(event)
    attrs = event.user_attributes
    User.create!(
      scim_id: attrs[:scim_id],
      email: attrs[:email],
      first_name: attrs.dig(:name, :givenName),
      last_name: attrs.dig(:name, :familyName),
      active: attrs[:active]
    )
  end

  def self.handle_user_updated(event)
    attrs = event.user_attributes
    user = User.find_by(scim_id: attrs[:scim_id])
    user&.update!(
      email: attrs[:email],
      first_name: attrs.dig(:name, :givenName),
      last_name: attrs.dig(:name, :familyName),
      active: attrs[:active]
    )
  end

  def self.handle_user_deleted(event)
    User.find_by(scim_id: event.user_id)&.destroy
  end
end

# Subscribe to events (in an initializer or event handler registration)
ActiveSupport::Notifications.subscribe(/TwoPercent::Domain::Events/) do |name, start, finish, id, payload|
  event = payload[:event]
  ScimUserSubscriber.call(event) if event.is_a?(TwoPercent::Domain::Events::Base)
end
```

### 2. Syncable Concern (Declarative)

For simpler integration, include the `TwoPercent::Syncable` concern in your domain models. This provides automatic SCIM → Domain synchronization:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include TwoPercent::Syncable

  syncable_as :user, scim_id_column: :scim_id do |scim_attrs|
    {
      first_name: scim_attrs.dig(:name, :givenName),
      last_name: scim_attrs.dig(:name, :familyName),
      email: scim_attrs[:email],
      active: scim_attrs[:active]
    }
  end
end

# app/models/group.rb
class Group < ApplicationRecord
  include TwoPercent::Syncable

  syncable_as :group, scim_id_column: :scim_id do |scim_attrs|
    {
      name: scim_attrs[:display_name],
      active: scim_attrs[:active]
    }
  end
end
```

**Syncable provides:**
- `user.scim_user` - Association to linked `TwoPercent::ScimUser` record
- `user.refresh_from_scim` - Pull latest SCIM data and update domain model
- `User.sync_from_scim_event(event)` - Sync from domain events

**Sync from events:**

```ruby
# Subscribe to events and sync automatically
ActiveSupport::Notifications.subscribe(/TwoPercent::Domain::Events/) do |name, start, finish, id, payload|
  event = payload[:event]
  case event
  when TwoPercent::Domain::Events::UserCreated, TwoPercent::Domain::Events::UserUpdated
    User.sync_from_scim_event(event)
  when TwoPercent::Domain::Events::UserDeleted
    User.sync_from_scim_event(event)
  when TwoPercent::Domain::Events::GroupCreated, TwoPercent::Domain::Events::GroupUpdated
    Group.sync_from_scim_event(event)
  when TwoPercent::Domain::Events::GroupDeleted
    Group.sync_from_scim_event(event)
  end
end
```

**Important:** The attribute mapper block is **mandatory** and must explicitly map SCIM attributes to your domain model's attributes. This ensures you have full control over what data syncs and how it transforms.

### 3. Direct Model Access

Query `ScimUser` and `ScimGroup` models directly for read-only access to SCIM data:

```ruby
# Find user by SCIM ID
scim_user = TwoPercent::ScimUser.find_by_scim_id("user-123")

# Access SCIM attributes
scim_user.scim_data["email"]
scim_user.scim_data["name"]["givenName"]

# Get domain-friendly hash
attrs = scim_user.to_domain_attributes
# => { scim_id: "user-123", email: "...", name: { givenName: "...", familyName: "..." }, ... }

# Find group with members
group = TwoPercent::ScimGroup.includes(:scim_users).find_by_scim_id("group-456")
group.scim_users # => Array of ScimUser records
```

**Available Models:**
- `TwoPercent::ScimUser` - Stores user SCIM data
- `TwoPercent::ScimGroup` - Stores group SCIM data (departments, territories, roles, etc.)

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
