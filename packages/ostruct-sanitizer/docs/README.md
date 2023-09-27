# OStruct::Sanitizer

[![Build Status](https://travis-ci.org/powerhome/ostruct-sanitizer.svg?branch=master)](https://travis-ci.org/powerhome/ostruct-sanitizer)

Provides Rails-like sanitization hooks to be applied to OpenStruct fields upon their assignment, allowing for better encapsulation of such rules and simple extensibility.

This module provides a few built-in sanitization rules, all built upon the basic `#sanitize` method used as building block.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ostruct-sanitizer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ostruct-sanitizer

## Usage

More complex sanitization rules may be created using the `#sanitize` method.

```ruby
require "ostruct"
require "ostruct/sanitizer"

class User < OpenStruct
  include OStruct::Sanitizer

  truncate :first_name, :last_name, length: 10
  alphanumeric :city, :country
  strip :email, :phone

  sanitize :age do |value|
    # Apply more complex sanitization rule to the value of "age" returning the
    # final, sanitized value.
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ostruct-sanitizer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
