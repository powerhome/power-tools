# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cobra::Plugin do
  it "is the gem's default lint_roller plugin" do
    expect(Gem.loaded_specs["rubocop-cobra"].metadata["default_lint_roller_plugin"]).to eq(described_class.name)
  end

  it "points RuboCop at the gem's default configuration" do
    rules = described_class.new.rules(nil)

    expect(rules.type).to eq(:path)
    expect(rules.value.to_s).to end_with("config/default.yml")
  end

  it "enables the Cobra cops in the integrated configuration" do
    expect(RuboCop::ConfigLoader.default_configuration.for_cop("Cobra/GemRequirement")["Enabled"]).to be(true)
  end
end
