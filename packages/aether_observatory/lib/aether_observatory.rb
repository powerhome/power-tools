# frozen_string_literal: true

require "active_support/all"
require "aether_observatory/backend/notifications"
require "aether_observatory/configuration"
require "aether_observatory/railtie" if defined?(Rails)

module AetherObservatory
  mattr_accessor :configuration, default: Configuration

  class << self
    delegate :configure, :config, to: :configuration
  end
end

require "aether_observatory/event_base"
require "aether_observatory/observer_base"
