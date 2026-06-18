# frozen_string_literal: true

Rails.application.config.to_prepare do
  TwoPercent.configure do |config|
    # Authentication configuration (allow all for tests)
    config.authenticate = ->(*) { true }

    # Enable all group resource types for comprehensive test coverage
    config.group_resource_types = %w[Groups Departments Territories Roles Titles]
  end
end
