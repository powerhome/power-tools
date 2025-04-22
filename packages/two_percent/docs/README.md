# TwoPercent [![Build Status](https://travis-ci.org/powerhome/two_percent.svg?branch=master)](https://travis-ci.org/powerhome/two_percent)

## What is TwoPercent?

TwoPercent is a lightweight [SCIM](https://scim.cloud/) provisioning interface designed for [Cloud Service Providers (CSPs)](https://datatracker.ietf.org/doc/html/rfc7642#section-2.2.2).

The primary role of TwoPercent is to respond to SCIM resource endpoints and forward those events to configured observer endpoints. This allows CSPs to subscribe to SCIM events and handle them to meet the specific needs of their software.

TwoPercent also maintains a local copy of SCIM resource data, giving CSPs convenient access to current user and group information.


## Installation

Add to your application with bundle

```ruby
bundle add two_percent
```

Then, if your project is the host application, require the engine in your `application.rb`:

```ruby
require "active_record/railtie"
require "two_percent/engine"
```

If your project will just subscribe to events, then you don't need the engine.

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
