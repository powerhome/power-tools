# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "combustion"
require "data_tracker"

Combustion.initialize! :active_record do |app|
  app.config.active_record.sqlite3.represent_boolean_as_integer = true
end

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
