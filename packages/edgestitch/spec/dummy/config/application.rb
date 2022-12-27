# frozen_string_literal: true

require_relative "boot"

require "active_record/railtie"

Bundler.require(*Rails.groups)

require "edgestitch/railtie"

require_relative "../engines/marketing/lib/marketing/engine"
require_relative "../engines/payroll/lib/payroll/engine"
require_relative "../engines/sales/lib/sales/engine"

module Dummy
  class Application < Rails::Application
    config.load_defaults 6.0

    config.active_record.schema_format = :sql
  end
end
