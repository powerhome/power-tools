# frozen_string_literal: true

require "spec_helper"

RSpec.describe DepShield do
  it "has a version number" do
    expect(DepShield::VERSION).not_to be nil
  end

  context "#raise_or_capture!" do
    it "invokes Deprecation class" do
      args = { name: "my_test_dep", message: "Test message!", callstack: [] }

      expect(DepShield::Deprecation).to receive_message_chain(:new, :raise_or_capture!)

      DepShield.raise_or_capture!(**args)
    end
  end
end
