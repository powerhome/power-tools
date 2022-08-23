# frozen_string_literal: true

require "bundler"
require "combustion"

require "active_record/railtie" # active_record has to be loaded before cancan
require "consent/engine"

Combustion.initialize! :active_record do |app|
  app.config.consent.paths << app.root.join("app", "permissions")
end

require "cancan/matchers"
require "rspec/rails"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.use_transactional_fixtures = true
end
