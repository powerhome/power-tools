# frozen_string_literal: true

require 'consent/reloader'

module Consent
  # Plugs consent permission load to the Rails class loading cycle
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      default_path = app.root.join('app', 'permissions')
      config.consent = Consent::Reloader.new(
        default_path,
        ActiveSupport::Dependencies.mechanism
      )
    end

    config.after_initialize do |app|
      app.config.consent.execute
    end

    initializer 'initialize consent permissions reloading' do |app|
      app.reloaders << config.consent
      ActiveSupport::Dependencies.autoload_paths -= config.consent.paths
      config.to_prepare { app.config.consent.execute_if_updated }
    end
  end
end
