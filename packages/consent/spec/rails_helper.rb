# frozen_string_literal: true

require "spec_helper"
require "combustion"

# If you're using all parts of Rails:
Combustion.initialize! :active_record

require "consent/railtie"
require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
