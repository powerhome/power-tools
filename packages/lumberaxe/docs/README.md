# Lumberaxe

Lumberaxe handles logging output formatting.

# Usage

After installing the gem, add any additional log tags you would like

```ruby
# application.rb

config.log_tags = [
  ->(req) { "request_id=#{req.uuid}" },
  ->(req) { "IP=#{req.remote_ip}" },
]
```

Updating the formatter for your webserver is also recommended.

```ruby
# puma.rb

log_formatter do |message|
  {
    level: "INFO",
    time: Time.now,
    progname: "puma",
    message: message,
  }.to_json.concat("\r\n")
end
```
