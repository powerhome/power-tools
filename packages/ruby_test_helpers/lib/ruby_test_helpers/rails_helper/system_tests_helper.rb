# frozen_string_literal: true

module RubyTestHelpers
  module RailsHelper
    module SystemTestsHelper
      def self.load(in_context:)
        instance_method(:helper).bind_call(in_context)
      end

      def helper
        require "webdrivers"
        require "capybara"
        require "capybara_selenium"
        require "site_prism"

        Capybara.register_driver(:headless_firefox) do |app|
          options = Selenium::WebDriver::Firefox::Options.new(args: %w[--headless])

          Capybara::Selenium::Driver.new(
            app,
            browser: :firefox,
            options: options
          )
        end

        RSpec.configure do |config|
          config.before(:each, type: :system) do
            driven_by :headless_firefox
          end
        end
      end
    end
  end
end
