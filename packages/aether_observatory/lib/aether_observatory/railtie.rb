# frozen_string_literal: true

module AetherObservatory
  class Railtie < Rails::Railtie
    initializer "aether_observatory.logger" do
      AetherObservatory.config.logger ||= Rails.logger
    end
  end
end
