# frozen_string_literal: true

require "dep_shield"

module DepShield
  # Ties DepShield to rails deprecations system
  class Railtie < Rails::Railtie
    initializer "dep_shield.subscribe" do
      ActiveSupport::Notifications.subscribe("deprecation.rails") do |name, _start, _finish, _id, payload|
        message = payload[:message] || "this is deprecated in rails"
        callstack = payload[:callstack] || caller

        DepShield.raise_or_capture!(name: name, message: message, callstack: callstack)
      end  
    end
  end
end
