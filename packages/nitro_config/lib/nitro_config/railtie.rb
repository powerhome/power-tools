# frozen_string_literal: true

module NitroConfig
  # Hook into Rails initialisation to make config available on application boot
  # @private
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      NitroConfig.load! app.root.join('config', 'config.yml'), Rails.env
    rescue Errno::ENOENT => e
      abort("Failed to initialize Nitro Config for #{app}:\n#{e.message}")
    end
  end

  private_constant :Railtie
end
