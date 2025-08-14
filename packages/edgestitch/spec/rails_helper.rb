# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "logger"

# Per SimpleCov documentation, this MUST be required before any appplication code
# https://github.com/colszowka/simplecov#getting-started
unless ENV["SIMPLECOV"] == "false"
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "/spec"
  end
end

require File.expand_path("dummy/config/environment", __dir__)

require "rspec/rails"
require "rspec/expectations"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
