# frozen_string_literal: true

require "consent"

module Consent
  # Plugs consent permission load to the Rails class loading cycle
  class Engine < Rails::Engine
    config.before_configuration do |app|
      default_path = app.root.join("app", "permissions")
      config.consent = Consent::Reloader.new(default_path)
    end

    config.after_initialize do |app|
      app.config.consent.execute
    end

    initializer "consent.reloader" do |app|
      app.reloaders << config.consent
      ActiveSupport::Dependencies.autoload_paths -= config.consent.paths
      config.to_prepare { app.config.consent.execute }
    end

    initializer "consent.accessible_through" do
      ActiveSupport.on_load(:active_record) do
        include Consent::ModelAdditions
      end
    end
  end
end
