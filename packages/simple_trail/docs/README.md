## What is SimpleTrail

SimpleTrail makes it easy to keep a history of attribute changes on a model.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_trail'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_trail


# Configuration

1. Add SimpleTrail config to your initializer file.
2. You need to set `current_session_user_id` to include user info in `simple_trail_histories` table.
3. You can optionally set `table_name_prefix` to customize default table name. Defaults to `simple_trail_histories`.
4. SimpleTrail stores backtrace info in `simple_trail_histories`. It defaults to `Rails.backtrace_cleaner`. You can optionally set it to your customized backtrace cleaner.

```ruby
SimpleTrail.config do
  table_name_prefix "myapp_"
  current_session_user_id { MyApp.current_session_user_id }
  backtrace_cleaner { YourCustom.backtrace_cleaner }
end
```

## Usage

```ruby
class Project < ApplicationRecord
  include ::SimpleTrail::Recordable
end
```

Inlcude `simple_trail` in your lib files if you need to call it there:

```ruby
require "simple_trail"
```


Now you can access the object history through `SimpleTrail.for(object)` like:

```ruby
project = Project.create
SimpleTrail.for(project).size
# => 1
```

The user performing the action will be recorded from the Thread local `:user_id`.

Then, require the engine in your `application.rb`

```ruby
require "simple_trail"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/power-tools.

## License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
