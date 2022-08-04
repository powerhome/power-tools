# frozen_string_literal: true

require "logger"
require "active_support"
require "nitro_logging/railtie" if defined?(Rails)
require "nitro_logging/log_chooser"

module NitroLogging
end
