# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Cobra
    # Integrates rubocop-cobra with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-cobra",
          version: VERSION,
          homepage: "https://github.com/powerhome/power-tools/blob/main/packages/rubocop-cobra/",
          description: "Cops that keep cobra (component-based Rails) apps modular."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        ConfigObsoletion.files << CONFIG_OBSOLETION unless ConfigObsoletion.files.include?(CONFIG_OBSOLETION)

        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: CONFIG_DEFAULT)
      end
    end
  end
end
