# frozen_string_literal: true

require "yaml"

require "nitro_config/options"

# When included in a Rails application, NitroConfig loads the
# configuration file at `config/config.yml` within the application
# directory and makes its values available at {NitroConfig.config}.
#
# Config values are loaded based on the Rails environment, permitting
# the specification of multiple environments' configurations in a
# single file.
module NitroConfig
  module Rspec
    def self.included(base)
      base.around(:each) do |example|
        NitroConfig.config.preserve! do
          example.run
        end
      end
    end
  end
end
