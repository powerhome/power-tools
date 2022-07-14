# frozen_string_literal: true

require 'yaml'

require 'nitro_config/options'

# When included in a Rails application, NitroConfig loads the
# configuration file at `config/config.yml` within the application
# directory and makes its values available at {NitroConfig.config}.
#
# Config values are loaded based on the Rails environment, permitting
# the specification of multiple environments' configurations in a
# single file.
module NitroConfig
  # Loads a configuration file as the global config, making it accessible via {NitroConfig.config}
  #
  # @param [String] file path to the config file to be loaded
  # @param [String] env the environment to load from the file (top level key)
  #
  # @return [NitroConfig::Options] the loaded configuration
  def self.load!(file, env)
    @config = NitroConfig::Options.new(YAML.load_file(file)[env])
  end

  # Provides the loaded global configuration
  #
  # @return [NitroConfig::Options] the loaded configuration
  def self.config
    @config ||= NitroConfig::Options.new
  end

  # @see NitroConfig::Options#get
  def self.get(*args)
    config.get(*args)
  end

  # @see NitroConfig::Options#get
  def self.get!(*args)
    config.get!(*args)
  end

  # Returns a function that will return the requested config when invoked.
  # This method is useful for fetching configurations in declarative contexts where the code will be invoked
  # in boot time. This will defer the fetching of the config to when needed.
  #
  # @see NitroConfig::Options#get
  # @return [Proc] a proc that takes any number of arguments and returns the requested config
  def self.get_deferred!(*args)
    ->(*_args) { config.get!(*args) }
  end

  require 'nitro_config/railtie' if defined?(Rails)
end
