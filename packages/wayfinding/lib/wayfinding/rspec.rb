# frozen_string_literal: true

require "wayfinding"

module Wayfinding
  # Spec helpers for applications consuming Wayfinding.
  #
  #   require "wayfinding/rspec"
  #
  # Each example runs inside Wayfinding.preserve!, so destinations registered in
  # a spec are rolled back afterwards. Use #stub_destination rather than mocking
  # Wayfinding itself.
  module RSpecHelpers
    # Register a destination that resolves to a fixed value, with no engine or
    # route helpers involved.
    #
    #   stub_destination(:home, "/homes/1")
    #   stub_destination(:home) { |home| "/homes/#{home.id}" }
    def stub_destination(name, path = nil, **attributes, &resolver)
      resolver ||= proc { |*, **| path }

      Wayfinding.register(name: name, **attributes, &resolver)
    end
  end
end

RSpec.configure do |config|
  config.include Wayfinding::RSpecHelpers

  config.around do |example|
    Wayfinding.preserve! { example.run }
  end
end
