# frozen_string_literal: true

require "two_percent"

module TwoPercent
  class Engine < ::Rails::Engine
    isolate_namespace TwoPercent
    config.generators.api_only = true

    initializer :append_migrations do |app|
      unless app.root.to_s.match? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "two_percent.scim_json" do
      mime_type = "application/scim+json"

      Mime::Type.register mime_type, :scim

      ActionDispatch::Request.parameter_parsers[Mime::Type.lookup(mime_type).symbol] = ->(body) do
        JSON.parse(body) if body
      end
    end
  end
end
