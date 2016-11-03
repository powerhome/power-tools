module Consent
  # Plugs consent permission load to the Rails class loading cycle
  class Railtie < Rails::Railtie
    config.before_configuration do
      default_path = Rails.root.join('app', 'permissions')
      config.consent = Struct.new(:paths).new([default_path])
    end

    config.to_prepare do
      Consent.subjects.clear
      Consent.load_subjects! Rails.application.config.consent.paths
    end

    config.after_initialize do
      permissions_paths = config.consent.paths.map(&:to_s)
      ActiveSupport::Dependencies.autoload_paths -= permissions_paths
    end
  end
end
