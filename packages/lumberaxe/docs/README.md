# Lumberaxe

Lumberaxe handles logging output formatting.

# Usage

After installing the gem, require it as part of your application configuration.

```ruby
# application.rb

require "lumberaxe"
```

## Setting JSON logging

To set up JSON logging on puma, add this to your puma config:

```ruby
# puma.rb

require "lumberaxe"

log_formatter(&Lumberaxe.puma_formatter)
```

If you don't have a tool for parsing JSON in local development, you can add this:

```ruby
# development.rb

config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
```
