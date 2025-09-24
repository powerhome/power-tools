# frozen_string_literal: true

module AetherObservatory
  module Configuration
    include ActiveSupport::Configurable

    config_accessor :logger
  end
end
