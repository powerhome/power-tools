# frozen_string_literal: true

module Payroll
  class Engine < ::Rails::Engine
    isolate_namespace ::Payroll

    initializer :append_migrations do |app|
      app.config.paths["db/migrate"].push(*config.paths["db/migrate"].expanded)
    end
  end
end
