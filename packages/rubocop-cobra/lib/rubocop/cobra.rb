# frozen_string_literal: true

module RuboCop
  # @private
  module Cobra
    class Error < StandardError; end

    PROJECT_ROOT      = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT    = PROJECT_ROOT.join("config", "default.yml").freeze
    CONFIG_OBSOLETION = PROJECT_ROOT.join("config", "obsoletion.yml").freeze
    CONFIG            = YAML.safe_load(CONFIG_DEFAULT.read).freeze

    private_constant(:CONFIG_DEFAULT, :CONFIG_OBSOLETION, :PROJECT_ROOT)

    require_relative "cobra/inject"
    require_relative "cobra/version"
  end
end
