# Lumberaxe

Lumberaxe handles logging output formatting.

# Usage

After installing the gem, add any additional log tags you would like

```ruby
# application.rb

require "lumberaxe"

config.log_tags = [
  ->(req) { "request_id=#{req.uuid}" },
  ->(req) { "IP=#{req.remote_ip}" },
]
```

## Setting JSON logging

To set up JSON logging on puma, add this to your puma config:

```ruby
# puma.rb

log_formatter &Lumberaxe.puma_formatter
```
