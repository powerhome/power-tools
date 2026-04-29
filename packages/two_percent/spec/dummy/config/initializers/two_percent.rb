# frozen_string_literal: true

Rails.application.config.to_prepare do
  TwoPercent.configure do |config|
    # Repository configuration (required for SCIM domain models)
    config.user_repository_class = TwoPercent::ScimUser
    config.group_repository_class = TwoPercent::ScimGroup

    # Authentication configuration (allow all for tests)
    config.authenticate = ->(*) { true }
  end
end
