# frozen_string_literal: true

module TwoPercent
  class Engine < ::Rails::Engine
    isolate_namespace TwoPercent
    config.generators.api_only = true
  end
end
