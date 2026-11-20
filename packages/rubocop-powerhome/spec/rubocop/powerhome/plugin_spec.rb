# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe RuboCop::Powerhome::Plugin do
  it "is the gem's default lint_roller plugin" do
    expect(Gem.loaded_specs["rubocop-powerhome"].metadata["default_lint_roller_plugin"]).to eq(described_class.name)
  end

  it "points RuboCop at the gem's default configuration" do
    rules = described_class.new.rules(nil)

    expect(rules.type).to eq(:path)
    expect(rules.value.to_s).to end_with("config/default.yml")
  end

  describe "configuration loaded through `plugins: rubocop-powerhome`" do
    subject(:config) do
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".rubocop.yml")
        File.write(path, "plugins:\n  - rubocop-powerhome\n")
        RuboCop::ConfigLoader.configuration_from_file(path, check: false)
      end
    end

    it "applies the powerhome overrides" do
      expect(config.for_cop("Style/StringLiterals")["EnforcedStyle"]).to eq("double_quotes")
      expect(config.for_cop("Rails/FilePath")["EnforcedStyle"]).to eq("arguments")
    end

    it "allows long describe and context blocks" do
      expect(config.for_cop("Metrics/BlockLength")["AllowedMethods"]).to include("describe", "context")
    end

    it "applies the bundled extensions' own defaults" do
      expect(config.for_cop("Rails/FilePath")["SupportedStyles"]).to eq(%w[slashes arguments])
      expect(config.for_department("Rake")["Include"]).to include("**/*.rake")
      expect(config.for_cop("Performance/Casecmp")).to include("Enabled" => false, "Safe" => false)
      expect(config.for_cop("RSpec/ExampleLength")["Max"]).to eq(5)
    end
  end
end
