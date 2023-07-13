# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/powerhome"
require_relative "rubocop/cop/naming_cops"
require_relative "rubocop/cop/style_cops"

def load_rubocop_extension(extension)
  RuboCop::ConfigLoader.add_loaded_features(extension)
  require extension
end

load_rubocop_extension "rubocop-performance"
load_rubocop_extension "rubocop-rails"
load_rubocop_extension "rubocop-rake"
load_rubocop_extension "rubocop-rspec"

RuboCop::Powerhome::Inject.defaults!
