# frozen_string_literal: true

module AetherObservatory
  class Railtie < Rails::Railtie
    initializer "aether_observatory.logger" do
      AetherObservatory.config.logger ||= Rails.logger
    end

    initializer "aether_observatory.reloader" do
      ActiveSupport::Reloader.before_class_unload do
        ObserverBase.descendants.each(&:stop)
      end
    end
  end
end
