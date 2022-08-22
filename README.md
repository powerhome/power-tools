# Consent [![Build Status](https://travis-ci.org/powerhome/consent.svg?branch=master)](https://travis-ci.org/powerhome/consent)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consent'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install consent

## What is Consent

Consent makes defining permissions easier by providing a clean, concise DSL for authorization so that all abilities do not have to be in your `Ability`
class.

Consent takes application permissions and models them so that permissions are organized and can be defined granularly. It does so using the
following models:

* View: A collection of objects limited by a given condition.
* Action: An action performed on top of the objects limited by the view. For example, one user could only `:view` something, while another could `:manage` it.
* Subject: Holds the scope of the actions.
* Permission: What is given to the user. Combines a subject, an action and
a view.

## What Consent Is Not

Consent isn't a tool to enforce permissions -- it is intended to be used with CanCanCan and is only to make permissions more easily readable and definable.

## Subject

The subject is the central point of a group of actions and views. It will typically
be an `ActiveRecord` class, a `:symbol`, or any Plain Old Ruby Object.

You define a subject with the following DSL:

```ruby
Consent.define Project, 'Our Projects' do
  #in this case, Project is the subject
  # and `Our Projects` is the description that makes it clear to users
  # what the subject is acting upon.
  …
end
```

The scope is the action that's being performed on the subject. It can be anything, but will typically be an ActiveRecord class, a `:symbol`, or a PORO.

For instance:

```ruby
Consent.define :features, 'Beta Features' do
  # whatever you put inside this method defines the scope
end
```

## Views

Views are the rules that limit the access to actions. For instance,
a user may see a `Project` from his department, but not from others. That rule
could be enforced with a `:department` view, defined like this:

### Hash Conditions

This is probably the most commonly used and is useful, for example,
when the view can be defined using a where condition in an ActiveRecord context.
It follows a match condition and will return all objects that meet the criteria
and is based off a boolean:

```ruby
Consent.define Project, 'Projects' do
  view :department, "User's department only" do |user|
    { department_id: user.id }
  end
end
```

Although hash conditions (matching object's attributes) are recommended,
the constraints can be anything you want. Since Consent does not enforce the
rules, those rules are directly given to CanCan. Following [CanCan rules](https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities%3A-Best-Practice)
for defining abilities is recommended.

### Object Conditions

If you're not matching for equal values, then you would need to use an object
condition, which matches data based off a range.

If you already have an object and want to check to see whether the user has
permission to view that specific object, you would use object conditions.

If your needs can't be satisfied by hash conditions, it is recommended that a
second condition is given for constraining object instances. For example, if you
want to restrict a view for smaller volume projects:

```ruby
Consent.define Project, 'Projects' do
  view :small_volumes, "User's department only",
    -> (user) {
      ['amount < ?', user.volume_limit]
    end,
    -> (user, project) {
      project.amount < user.volume_limit
    }
end
```

For object conditions, the latter argument will be the referred object, while the
former will be the context given to the [Permission](#permission) (also check
[CanCan integration](#cancan-integration)).

## Action

An action is anything you can perform on a given subject. In the example of
Features this would look like the following using Consent's DSL:

```ruby
Consent.define :features, 'Beta Features' do
  action :beta_chat, 'Beta Chat App'
end
```

To associate different views to the same action:

```ruby
Consent.define Project, 'Projects' do
  # returns conditions that can be used as a matcher for objects so the matcher
  # can return true or false (hash version)
  view :department, "User's department only" do |user|
    { department_id: user.id }
  end
  view :future_projects, "User's department only",
    # returns a condition to be applied to a collection of objects
    -> (_) {
      ['starts_at > ?', Date.today]
    end,
    # returns true/false based on a condition -- to use this, you must pass in
    # an instance of an object in order to check the permission
    -> (user, project) {
      project.starts_at > Date.today
    }

  action :read, 'Read projects', views: [:department, :future_projects]
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

Consent provides a CanCan ability (Consent::Ability) to integrate your
permissions with frameworks like Rails. To use it with Rails check out the
example at [Ability for Other Users](https://github.com/CanCanCommunity/cancancan/wiki/Ability-for-Other-Users)
on CanCanCan's wiki.

In the ability you define the scope of the permissions. This is typically an
user:

```ruby
Consent::Ability.new(user.permissions, user)
```

The first parameter given to the ability is the permissions hash, seen at
[Permission](#permission). The following parameters are the permission context.
These parameters are given directly to the condition blocks defined by the views
in the exact same order, so it's up to you to define what your context is.

## Rails Integration

Consent is integrated into Rails with `Consent::Railtie`. To define where
your permission files will be, use `config.consent.path`. This defaults to
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
