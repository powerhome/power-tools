# AuditTracker

AuditTracker helps you centralize data tracking configuration to be used across different models.

## Installation

Install the gem and add it to the application's Gemfile by executing:

    $ bundle add audit_tracker

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install audit_tracker

## Usage Example

In this example, we'll track the actors that created or updated different models, like the user, title, and their department at the time. This is represented like this in AuditTracker:

```ruby
AuditTracker.setup do
  tracker :user do
    value { ::Internal::Current.user }
    create :created_by, foreign_key: :created_by_id, class_name: "::Internal::User"
    update :updated_by, foreign_key: :updated_by_id, class_name: "::Internal::User"
  end
  tracker :user_department do
    value { ::Internal::Current.user&.department }
    create :created_by_department, foreign_key: :created_by_department_id, class_name: "::Internal::Department"
    update :updated_by_department, foreign_key: :updated_by_department_id, class_name: "::Internal::Department"
  end
end
```

Then, enable the trackers on each model:

```ruby
class Lead < ApplicationRecord
  track_data user: true, user_department: true
end
```

This will create each relation setup by the tracker:

```ruby
lead.created_by => User
lead.created_by_department => Department
lead.updated_by => User
lead.updated_by_department => Department
```

When a relation is disabled, the tracker is not setup:

```ruby
module Internal
  class Home < ::Internal::ApplicationRecord
    track_data user: true
  end
end

home.created_by => User
home.created_by_department => NoMethodError
home.updated_by => User
home.updated_by_department => NoMethodError
```

### Disabling individual relations

To enable each relation, AuditTracker will first check if the column exists (`foreign_key`). If it doesn't exist, the relation won't be created, and the tracker won't be enabled for it.

```ruby
module Internal
  class Sale < ::Internal::ApplicationRecord
    track_data user: true
  end
end

Sale.column_names => ["id", "price", "updated_by_id"]
sale.created_by => User
sale.created_by_department => NoMethodError
sale.updated_by => NoMethodError
sale.updated_by_department => NoMethodError
```

### Overriding relation options

To override a relation option in a tracker, use the tracker options:

```ruby

module Internal
  class Score < ::Internal::ApplicationRecord
    track_data(
      user: {
        created_by: {
          class_name: "::Internal::ManagerUser",
          value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) },
        },
        updated_by: {
          class_name: "::Internal::ManagerUser",
          value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) },
        },
      }
    )
  end
end

score.created_by => ManagerUser
score.updated_by => ManagerUser
```

## Internal Example

The above example lives in our [specs](specs/internal).


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power-tools.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
