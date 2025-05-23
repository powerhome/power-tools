# frozen_string_literal: true

require "rspec/expectations"
require "aether_observatory/backend/memory"

RSpec::Matchers.define :create_event do |expected, **attrs|
  match do |actual|
    actual.call

    AetherObservatory::Backend::Memory.instrumented.any? do |event|
      (event.is_a?(expected) && attrs.empty?) || RSpec::Matchers::BuiltIn::HaveAttributes.new(attrs).matches?(event)
    end
  end

  failure_message do |*|
    "Block did not create a #{expected.inspect} #{attrs_message}"
  end

  failure_message_when_negated do |*|
    "Block created event(s) #{expected.inspect} #{attrs_message}"
  end

  def supports_block_expectations?
    true
  end

  def attrs_message
    return unless expected[1].any?

    expected[1].inspect
  end
end

module AetherObservatory
  module Rspec
    module EventHelper
      def self.included(base)
        base.before { AetherObservatory::Backend::Memory.instrumented.clear }
        base.around do |example|
          current_backend = AetherObservatory::EventBase.backend
          AetherObservatory::EventBase.backend = AetherObservatory::Backend::Memory
          example.run
        ensure
          AetherObservatory::EventBase.backend = current_backend
        end
      end
    end
  end
end
