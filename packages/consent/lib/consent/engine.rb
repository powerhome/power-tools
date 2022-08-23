# frozen_string_literal: true

require "consent"

module Consent
  # Plugs consent permission load to the Rails class loading cycle
  class Engine < Rails::Engine
    config.before_configuration do |app|
      default_path = app.root.join("app", "permissions")
      config.consent = Consent::Reloader.new(
        default_path,
        ActiveSupport::Dependencies.mechanism
      )
    end

    config.after_initialize do |app|
      app.config.consent.execute
    end

    initializer "consent.reloader" do |app|
      app.reloaders << config.consent
      ActiveSupport::Dependencies.autoload_paths -= config.consent.paths
      config.to_prepare { app.config.consent.execute }
    end

    # initializer "consent.append_migrations" do |app|
    #   unless app.root.to_s.match? root.to_s
    #     config.paths["db/migrate"].expanded.each do |expanded_path|
    #       app.config.paths["db/migrate"] << expanded_path
    #     end
    #   end
    # end
  end
end
