# frozen_string_literal: true

module Stagecoach
  class Error < StandardError; end

  class ReadOnlyError < Error; end

  class UnsupportedTypeError < Error; end

  class ConfigurationError < Error; end
end
