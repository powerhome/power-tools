module Nitro
  module Consent
    class Railtie < Rails::Railtie
      config.consent = Struct.new(:path).new
      config.consent.path = Rails.root.join('app', 'permissions')

      config.to_prepare do
        Nitro::Consent.subjects.clear
        Dir[Rails.application.config.consent.path.join('*.rb')].each(&method(:load))
      end

      config.after_initialize do
        ActiveSupport::Dependencies.autoload_paths.delete_if do |autoload_path|
          autoload_path.eql?(config.consent.path.to_s)
        end
      end
    end
  end
end
