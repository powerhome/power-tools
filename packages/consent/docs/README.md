# Consent [![Build Status](https://travis-ci.org/powerhome/consent.svg?branch=master)](https://travis-ci.org/powerhome/consent)

## What is Consent

Consent makes defining permissions easier by providing a clean, concise DSL for authorization
so that all abilities do not have to be in your `Ability` class.

Also, Consent adds an `Authorizable` model, so that you can easily grant permissions to your
ActiveRecord models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consent'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install consent

Then, require the engine in your `application.rb`

```ruby
require "active_record/railtie"
require "consent/engine"
```

If you wish to use the activerecord adapter (`accessible_by` and `accessible_through`), you must load `active_record/railtie` before loading the `consent/engine`.

### Install and run the migrations

Copy and execute the migrations:

    $ rails consent_engine:install:migrations
    $ rails db:migrate

This will create the `consent_histories` and `consent_permissions` tables. If you want to use a different table prefix, you should set `Consent.table_name_prefix =` before you execute the migrations. I.e.:

```ruby
# config/initializers/consent.rb

require "consent"

Consent.table_name_prefix = "my_app_"
```

## Authorizable

To grant permissions, you need an authorizable model. For our example we'll call it `Role`:

```ruby
class Role < ApplicationRecord
  include ::Consent::Authorizable
end
```

You can now grant permissions to role with `grant`, `grant_all`, and `grant_all!`:

```ruby
role = Role.new
role.grant subject: Project, action: :update, view: :department
# OR
role.grant_all({ project: { update: :department } })
# OR
role.grant_all({ project: { update: :department } }, replace: true) # to replace everything
# OR
role.grant_all!({ project: { update: :department } }, replace: true) # to grant and save

role.permissions
=> [#<Consent::Permission subject: Project, action: :update, view: :department>]
```

In the above example, we're granting `:department` view to perform `:update` in the `Project` subject.

You can now create a `Consent::Ability` using the permissions granted to the role:

```ruby
ability = Consent::Ability.new(user, permissions: role.permissions)
```

## Defining permissions and views

Generate permissions with the `consent:permissions` generator. I.e:

    $ rails g consent:permissions Projects
    create  app/permissions/projects.rb
    create  spec/permissions/projects_spec.rb

This will generate the permission definition:

```ruby
Consent.define Project, "Projects" do
  #in this case, Project is the subject
  # and `Our Projects` is the description that makes it clear to users
  # what the subject is acting upon.
  …
end
```

We can now define the `:update` action and a couple of different views:

```ruby
Consent.define Project, "Our Projects"  do
  view :all, "All projects"

  view :department, "Projects from their department" do |user|
    { department_id: user.department_id }
  end

  view :team, "Projects from their team" do |user|
    { team_id: user.team_id }
  end

  action :update, views: %i[department team all]
end
```

The `:department` view will restrict the user to projects with matching `department_id`. That
means that for `Project.accessible_by(ability, :update)`, with an ability using a User with
department_id = 13, it will run a query similar to:

```sql
> user = User.new(department_id: 13)
> ability = Consent::Ability.new(user)
> ability.consent subject: Project, action: :update, view: :department
> Project.accessible_by(user).to_sql
"SELECT * FROM projects WHERE department_id = 1"
```

### Subject

The subject is the central point of a group of actions and views. It will typically
be an `ActiveRecord`, a `:symbol`, or any plain ruby class.

### Views

Views are the rules that limit access to actions. For instance, a user may see a `Project`
from his department, but not from others. You can enforce it with a `:department` view,
as in the examples below:

### Hash Conditions

Probably the most commonly used. When the view can be defined using a `where` scope in
an ActiveRecord context. It follows a match condition and will return all objects that meet
the criteria:

```ruby
Consent.define Project, 'Projects' do
  view :department, "User's department only" do |user|
    { department_id: user.id }
  end
end
```

Although hash conditions (matching object's attributes) are recommended, the constraints can
be anything you want. Since Consent does not enforce the rules, those rules are directly given
to CanCan. Following [CanCan rules](https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities%3A-Best-Practice)
for defining abilities is recommended.

### Object Conditions

If you're not matching for equal values, then you would need to use an object condition.

If you already have an object and want to check to see whether the user has permission to view
that specific object, you would use object conditions.

If your needs can't be satisfied by hash conditions, it is recommended that a second condition
is given for constraining object instances. For example, if you want to restrict a view for smaller
volume projects:

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
first will be the context given to the [Permission](#permission) (also check
[CanCan integration](#cancan-integration)).

### Action

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

### Permission

Permission is what is granted to a role, or a user. It grants the ability to perform an *action*,
on a limited scope (*view*) of the *subject*.

## CanCan Integration

Consent provides a CanCan ability (Consent::Ability) that can be initialized with a group of
granted permissions. You can initialize a `Consent::Ability` with:

```ruby
Consent::Ability.new(*context, super_user: <true|false>, apply_defaults: <true|false>, permissions: [Consent::Permission, ...])
```

- `*context` is what is given to the view evaluating permission rules. That is typically a user;
- `super_user` makes the ability to respond to `true` to any `can?` questions, and yields no
  restrictions in any `accessible_by` and `accessible_through` queries;
- `apply_defaults` grants actions with the `default_view` set automatically.
- `permissions` is a collection of permissions to grant to the user

### Manually consent permissions

You can manually grant permissions with `consent`. You could possibly subclass
`Consent::Ability` to consent some specific permissions by default:

```ruby
class MyAbility < Consent::Ability
  def initialize(...)
    super(...)

    consent action: :read, subject: Project, view: :department
  end
end
```

You can also consent full-access by not specifying the view:

```ruby
  consent action: :read, subject: Project
```

Consenting the same permission multiple times is handled as a Union by CanCanCan:

```ruby
class MyAbility < Consent::Ability
  def initialize(user)
    super user

    consent :read, Project, :department
    consent :read, Project, :future_projects
  end
end

user = User.new(department_id: 13)
ability = MyAbility.new(user)

Project.accessible_by(ability, :read).to_sql
=> SELECT * FROM projects WHERE ((department_id = 13) OR (starts_at > '2021-04-06'))
```

## Rails Integration

Consent is integrated into Rails with `Consent::Engine`. To define where
your permission files will be, use `config.consent.path`. This defaults to
`#{Rails.root}/app/permissions/` to conform to Rails' standards.

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
