# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler"

Bundler.require(:development)

require "data_tracker"

Combustion.initialize! :active_record do |app|
  app.config.active_record.sqlite3.try(:represent_boolean_as_integer=, true)
end

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |with|
    with.syntax = :expect
  end
  config.after { Internal::Current.user = nil }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
