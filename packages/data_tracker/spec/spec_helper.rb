# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler"

Bundler.require(:development)

Combustion.initialize! :active_record do |app|
  app.config.active_record.sqlite3.represent_boolean_as_integer = true
end

DataTracker.setup do
  tracker(:user) do
    create :created_by, foreign_key: :created_by_id, class_name: "::Internal::User"
    update :updated_by, foreign_key: :updated_by_id, class_name: "::Internal::User"
    value { Internal::Current.user }
  end

  tracker(:department) do
    create :created_by_department, foreign_key: :created_by_department_id, class_name: "::Internal::Department"
    update :updated_by_department, foreign_key: :updated_by_department_id, class_name: "::Internal::Department"
    value { Internal::Current.user&.department }
  end
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
