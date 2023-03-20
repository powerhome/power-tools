# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

# Per SimpleCov documentation, this MUST be required before any appplication code
# https://github.com/colszowka/simplecov#getting-started
unless ENV["SIMPLECOV"] == "false"
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "/spec"
  end
end

require "spec_helper"

require File.expand_path "dummy/config/environment", __dir__

require "rspec/rails"
require "rspec/expectations"

SimpleTrail::Config.config do
  current_session_user_id { 13 }
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 1_000_000
  end
end
