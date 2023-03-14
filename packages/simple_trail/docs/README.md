## What is SimpleTrail

SimpleTrail makes it easy to keep history of attribute changes on a model.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_trail'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_trail

## Usage

```ruby
class Project < ApplicationRecord
  include ::SimpleTrail::Recordable
end
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
