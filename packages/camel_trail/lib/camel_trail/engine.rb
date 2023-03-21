# frozen_string_literal: true

module CamelTrail
  class Engine < ::Rails::Engine
    isolate_namespace CamelTrail

    config.generators do |g|
      g.test_framework :rspec
    end

    config.generators do |g|
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "camel_trail.backtrace_cleaner" do
      CamelTrail::Config.backtrace_cleaner ||= Rails.backtrace_cleaner
    end
  end
end
