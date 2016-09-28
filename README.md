# Nitro::Consent

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nitro-consent'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nitro-consent

## What is Consent

Consent is a domain model for application permissions. It primarily defines the
following models:

* View: A subset of the objects. Term borrowed from database systems.
* Action: An action performed on top of the objects limited by the view.
* Subject: The scope of the actions.
* Permission: Is what is given to the user. Combines a subject, an action and
a view.

Consent also includes a DSL for defining the modeling of your application's
permission, was the main goal of this madness :)

## What Consent isn't

Consent isn't a tool to enforce the permissions. Consent only defines them
in a way to be used by other tools like CanCan(Can). Consent is packaged with
a CanCan ability to enforce the permissions, though.

## Subject

The subject is the central point of a group of actions and views. It will tipically
be an `ActiveRecord` class, a PORO class or a `:symbol`.

You define a subject with the following DSL:

```ruby
Nitro::Consent.define Project, 'Projects' do
  …
end
```

The scope can be anything, but will typically be an ActiveRecord class, a PORO,
or a `:symbol`.

For instance, when defining a permission level feature access:

```ruby
Nitro::Consent.define :features, 'Beta Features' do
  …
end
```

## Views

Views is the definition of rules that limit the access to actions. For instance,
an user may see a `Project` from his department, but not from others. That rule
could be enforced with a `:department` view, defined like this:

### Hash Conditions

```ruby
Nitro::Consent.define Project, 'Projects' do
  view :department, "User's department only" do |user|
    { department_id: user.id }
  end
end
```

Although hash conditions (matching object's attributes) are the recommended,
the constraints can be anything you want. Since Consent does not enforce the
rules, those rules are directly given to CanCan. Following CanCan rules for
defining abilities is recommended.

### Object Conditions

If your needs can't be satisfied by hash conditions, it is recommended that a
second condition is given for constraining object instances. For example, if you
want to restrict a view for smaller volume projects:

```ruby
Nitro::Consent.define Project, 'Projects' do
  view :small_volumes, "User's department only",
    -> (user) {
      ['amount < ?', user.volume_limit]
    end,
    -> (user, project) {
      project.amount < user.volume_limit
    }
end
```

For objects conditions, the last argument will be the referred object, while the
prior will be the context given to the [Permission](#permission) (also check
[CanCan integration](#cancan-integration)).

## Action

An action is anything you can do on a given subject. In the example of Features
this would look like the following using Consent's DSL:

```ruby
Nitro::Consent.define :features, 'Beta Features' do
  action :beta_chat, 'Beta Chat App'
end
```

To associate different views to the same action:

```ruby
Nitro::Consent.define Project, 'Projects' do
  view :department, "User's department only" do |user|
    { department_id: user.id }
  end
  view :small_volumes, "User's department only",
    -> (user) {
      ['amount < ?', user.volume_limit]
    end,
    -> (user, project) {
      project.amount < user.volume_limit
    }

  action :read, 'Read projects' views: [:department, :small_volumes]
end
```

If you have a set of actions with the same set of views, you can use a
`with_defaults` block to simplify the writing:

```ruby
with_defaults views: [:department, :small_volumes] do
  action :read, 'Read projects'
  action :approve, 'Approve projects'
end
```

## Permission

A permission is what is consented to the user. It is the *permission* to perform
an *action* on a limited *view* of the *subject*. It marries the three concepts
to consent an access to the user.

A permission is not specified by the user, it is calculated from a permissions
hash owned by a `User`, or a `Role` on an application.

The permissions hash looks like the following:

```ruby
{
  project: {
    read: 'department',
    approve: 'small_volumes'
  }
}
```

In other words:

```ruby
{
  <subject>: {
    <action>: <view>
  }
}
```

### Full Access

Full (unrestricted by views) access is granted when view is `'1'`, `true` or
`'true'`. For instance:

In other words:

```ruby
{
  projects: {
    approve: true
  }
}
```

## CanCan Integration

Consent provides a CanCan ability (Nitro::Consent::Ability) to integrate your
permissions with frameworks like Rails. To use it with rails check out the
example at [Ability for Other Users](https://github.com/CanCanCommunity/cancancan/wiki/Ability-for-Other-Users)
on CanCanCan's wiki.

In the ability you define the scope of the permissions. This is typically an
user:

```ruby
Nitro::Consent::Ability.new(user.permissions, user)
```

The first parameter given to the ability is the permissions hash, seen at
[Permission](#permission). The following parameters are the permission context.
These parameters are given directly to the condition blocks defined by the views
in the exact same order, so it's up to you defining what your context is.

## Rails Integration

Consent is integrated into Rails with `Nitro::Consent::Railtie`. To define where
your permission files will be use `config.consent.path`. This is defaulted to
`app/permissions/` to conform to Rails' standards.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/consent.
