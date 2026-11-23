# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Powerhome
    # Integrates rubocop-powerhome with RuboCop's plugin system. Its default
    # configuration also loads the rubocop-performance, rubocop-rails,
    # rubocop-rake and rubocop-rspec plugins.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-powerhome",
          version: VERSION,
          homepage: "https://github.com/powerhome/power-tools/blob/main/packages/rubocop-powerhome/",
          description: "Powerhome Rubocop standard rules"
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: CONFIG_DEFAULT)
      end
    end
  end
end
