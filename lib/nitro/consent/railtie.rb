module Nitro
  module Consent
    class Railtie < Rails::Railtie
      config.before_configuration do
        default_path = Rails.root.join('app', 'permissions')
        config.consent = Struct.new(:path).new(default_path)
      end

      config.to_prepare do
        permission_files = Rails.application.config.consent.path.join('*.rb')

        Nitro::Consent.subjects.clear
        Dir[permission_files].each(&method(:load))
      end

      config.after_initialize do
        ActiveSupport::Dependencies.autoload_paths.delete_if do |autoload_path|
          autoload_path.eql?(config.consent.path.to_s)
        end
      end
    end
  end
end
