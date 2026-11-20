# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cobra::Inject do
  it "prints the loaded configuration path when RuboCop runs with --debug" do
    allow(RuboCop::ConfigLoader).to receive(:debug?).and_return(true)

    expect { described_class.defaults! }.to output(/configuration from .*default\.yml/).to_stdout
  end
end
