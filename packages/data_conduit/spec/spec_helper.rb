# frozen_string_literal: true

require "data_conduit"
require "webmock/rspec"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    WebMock.disable_net_connect!
  end

  config.after(:each) do
    WebMock.allow_net_connect!
  end
end
