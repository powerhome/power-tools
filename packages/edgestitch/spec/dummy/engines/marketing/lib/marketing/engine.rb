# frozen_string_literal: true

module Marketing
  class Engine < ::Rails::Engine
    isolate_namespace ::Marketing

    initializer :append_migrations do |app|
      app.config.paths["db/migrate"].push(*config.paths["db/migrate"].expanded)
    end
  end
end
