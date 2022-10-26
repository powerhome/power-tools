# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cobra do
  it "has a version number" do
    expect(RuboCop::Cobra::VERSION).not_to be nil
  end
end
