# frozen_string_literal: true

module DepShield
  class Deprecation
    attr_reader :name, :error, :stack

    def initialize(name:, message:, callstack:)
      @name = name
      @stack = cleaner.clean(callstack.map(&:to_s))
      @error = DepShield::Error.new("#{name}:\n#{message}", stack)
    end

    def raise_or_capture!
      Rails.logger.warn("NITRO DEPRECATION WARNING") { "#{error}\n#{stack}" }
      return if DepShield.todos.allowed?(name, stack)

      raise error unless NitroConfig.get("nitro_errors/capture_deprecation")

      Sentry.capture_exception(
        error,
        tags: { environment: Rails.env, deprecation_error: name }
      )
    end

  private

    def cleaner
      @cleaner ||= ActiveSupport::BacktraceCleaner.new.tap do |cleaner|
        cleaner.add_filter { |line| line.gsub(/^(.*?:.*?):.*/, '\1') }
        cleaner.add_silencer { |line| line.include?(ENV.fetch("GEM_HOME", nil)) }
        cleaner.add_silencer { |line| line.start_with?("bin/") }
      end
    end
  end
end
