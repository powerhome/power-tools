# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "spec_helper"

require File.expand_path "dummy/config/environment", __dir__

require "rspec/rails"
require "shoulda/matchers"
require "webmock/rspec"

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods, type: :request
  config.include Rails.application.routes.url_helpers, type: :request

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
end
