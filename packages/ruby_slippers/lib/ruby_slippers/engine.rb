require "sassc-rails"

module RubySlippers
  class Engine < ::Rails::Engine
    isolate_namespace RubySlippers

    config.generators do |g|
      g.test_framework :rspec
    end

    config.sass.load_paths ||= []
    config.assets.paths ||= []

    config.sass.load_paths << "#{Gem.loaded_specs['ruby_slippers'].full_gem_path}/app/assets/stylesheets/ruby_slippers"
  end
end
