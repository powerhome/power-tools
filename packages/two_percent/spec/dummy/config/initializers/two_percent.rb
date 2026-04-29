# frozen_string_literal: true

Rails.application.config.to_prepare do
  TwoPercent.configure do |config|
    # Authentication configuration (allow all for tests)
    config.authenticate = ->(*) { true }
  end
end
