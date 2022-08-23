# frozen_string_literal: true

require "spec_helper"
require "combustion"
require "consent/engine"

# If you're using all parts of Rails:
Combustion.initialize! :active_record do |app|
  app.config.consent.paths << app.root.join("app", "permissions")
end

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
