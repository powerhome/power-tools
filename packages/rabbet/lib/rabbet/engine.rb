# frozen_string_literal: true

require "sassc-rails"

module Rabbet
  # Define engine
  class Engine < ::Rails::Engine
    isolate_namespace Rabbet

    config.generators do |g|
      g.test_framework :rspec
    end

    config.sass.load_paths ||= []
    config.assets.paths ||= []

    config.sass.load_paths << "#{Gem.loaded_specs['rabbet'].full_gem_path}/app/assets/stylesheets/rabbet"
  end
end
