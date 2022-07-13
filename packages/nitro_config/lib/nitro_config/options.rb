# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/object/try"
require "active_support/hash_with_indifferent_access"

require "nitro_config/error"

module NitroConfig
  PATH_SEPARATOR = "/"

  # Representation of a config key-value tree with path-based access
  class Options < HashWithIndifferentAccess
    # Preserves values in the global configuration which might be altered within the yielded block.
    # This is useful for testing, where a test needs to assert behaviour with certain settings values,
    # but you want them to be restored for the next test.
    #
    # @example Preserving configuration in all tests
    #   config.around(:each) do |example|
    #     NitroConfig.preserve! do
    #       example.run
    #     end
    #   end
    #   OR
    #   config.include NitroConfig::Rspec
    #
    # @yield A block within which configuration can safely be altered, being restored on return
    def preserve!
      tmp = clone
      yield
      replace(tmp)
    end

    # Returns a configuration value by path
    #
    # @param [String,Array] path the path within the configuration to return, with nested keys "separated/like/this"
    # @param default a default value to return if the path is not found in the configuration
    #
    # @return The value extracted from configuration, of the type specified when declared.
    def get(path, default = nil)
      get!(path)
    rescue NitroConfig::Error
      default
    end

    # Returns a configuration value by path
    #
    # @param [String,Array] path the path within the configuration to return, with
    #   nested keys "separated/like/this", ['or', 'like', 'this']
    #
    # @return The value extracted from configuration, of the type specified when declared.
    #
    # @raise [NitroConfig::Error] when the configuration option is not found
    def get!(path)
      split_path = path.respond_to?(:split) ? path.split(PATH_SEPARATOR) : path
      split_path.flatten.reduce(self) do |config, key|
        raise(NitroConfig::Error, path) unless config.try(:has_key?, key)

        config[key]
      end
    end
  end
end
