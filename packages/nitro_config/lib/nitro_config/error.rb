# frozen_string_literal: true

module NitroConfig
  # Raised when a path cannot be found in the config tree
  class Error < StandardError
    def initialize(path)
      super "#{path} not found in app config! If you're working in development, you probably need to" \
            "`cp config/config_sample.yml config/config.yml` or create a symlink for convenience."
    end
  end
end
