# frozen_string_literal: true

require "pry-byebug"
require "stagecoach"
require "active_record/connection_adapters/trino_adapter"
require "webmock/rspec"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    WebMock.disable_net_connect!
  end

  config.after do
    WebMock.reset!
    WebMock.allow_net_connect!
  end
end
