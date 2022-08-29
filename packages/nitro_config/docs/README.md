# NitroConfig

When included in a Rails application, NitroConfig loads the configuration file at `config/config.yml` within the application directory and makes its values available at `NitroConfig.config`. Config values are loaded based on the Rails environment, permitting the specification of multiple environments' configurations in a single file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nitro_config'
```

And then execute:

    $ bundle

## Usage

Given the following example config file, the following examples demonstrate how to obtain these values.

```yaml
base: &base
  some:
    nested: value
  service:
    api: <%= ENV.fetch("SERVICE_API_URL", "http://localhost:3000/api") %>

development:
  <<: *base
  some:
    nested: devvalue

test:
  <<: *base
  some:
    nested: testvalue

```

    $ rails c
    [1] pry(main)> NitroConfig.config.get('some/nested')
    => "devvalue"
    [2] pry(main)> NitroConfig.config.get('some/other')
    => nil
    [3] pry(main)> NitroConfig.config.get!('some/other')
    NitroConfig::Error: some/other not found in app config!
    from /Users/ben/code/power/nitro/components/nitro_config/lib/nitro_config/options.rb:20:in `block in get!'
    [4] pry(main)> NitroConfig.config.get('some/other', 'default')
    => "default"
    [5] pry(main)> NitroConfig.config.get('service/api')
    => "http://localhost:3000/api"

    $ RAILS_ENV=test rails c
    [1] pry(main)> NitroConfig.config.get('some/nested')
    => "testvalue"

    $ SERVICE_API_URL="http://test.com" rails c
    [1] pry(main)> NitroConfig.config.get('service/api')
    => "http://test.com"
