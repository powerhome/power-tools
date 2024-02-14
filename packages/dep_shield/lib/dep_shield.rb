# frozen_string_literal: true

require "nitro_config"
require "sentry-ruby"

require_relative "dep_shield/deprecation"
require_relative "dep_shield/todos"
require_relative "dep_shield/version"

module DepShield
  class Error < StandardError
    def initialize(message, callstack)
      super(message)

      case callstack
      when Array
        set_backtrace callstack.map(&:to_s)
      when Thread::Backtrace::Location, String
        set_backtrace [callstack.to_s]
      end
    end
  end

module_function

  def todos
    @todos ||= DepShield::Todos.new
  end

  # Takes a deprecation message string. Warns, then raises or reports to Sentry
  #
  # @param name [String]
  # @param message [String]
  # @param callstack [Array<String>]
  # @yieldparam scope [Scope]
  # @return [Event, nil]
  def raise_or_capture!(name:, message:, callstack: caller, **)
    ::DepShield::Deprecation.new(
      name: name, message: message, callstack: callstack
    ).raise_or_capture!
  end
end
