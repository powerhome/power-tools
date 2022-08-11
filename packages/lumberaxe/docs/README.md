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

log_formatter &Lumberaxe.puma_formatter
```
