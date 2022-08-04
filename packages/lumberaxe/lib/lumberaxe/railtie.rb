# frozen_string_literal: true

module NitroLogging
  class Railtie < Rails::Railtie
    initializer "nitro_logging.configurations" do
      NitroLogging::LogChooser.log_level = Rails.application.config.log_level
    end
  end
end
