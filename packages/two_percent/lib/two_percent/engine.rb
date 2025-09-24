# frozen_string_literal: true

require "two_percent"

module TwoPercent
  class Engine < ::Rails::Engine
    isolate_namespace TwoPercent
    config.generators.api_only = true

    initializer "two_percent.scim_json" do
      mime_type = "application/scim+json"

      Mime::Type.register mime_type, :scim

      ActionDispatch::Request.parameter_parsers[Mime::Type.lookup(mime_type).symbol] = ->(body) do
        JSON.parse(body) if body
      end
    end
  end
end
