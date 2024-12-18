# frozen_string_literal: true

module AetherObservatory
  module Configuration
    include ActiveSupport::Configurable

    config_accessor(:logger) do
      defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end
  end
end
