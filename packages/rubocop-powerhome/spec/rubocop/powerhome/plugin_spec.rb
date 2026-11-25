# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "json"
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

    it "allows long refine, describe and context blocks" do
      expect(config.for_cop("Metrics/BlockLength")["AllowedMethods"]).to include("refine", "describe", "context")
    end

    it "applies the bundled extensions' own defaults" do
      expect(config.for_cop("Rails/FilePath")["SupportedStyles"]).to eq(%w[slashes arguments])
      expect(config.for_department("Rake")["Include"]).to include("**/*.rake")
      expect(config.for_cop("Performance/Casecmp")).to include("Enabled" => false, "Safe" => false)
      expect(config.for_cop("RSpec/ExampleLength")["Max"]).to eq(5)
    end

    it "enables the cops that keep application code off Rails.env and ENV" do
      expect(config.for_cop("Rails/Env")).to include("Enabled" => true)
      expect(config.for_cop("Rails/EnvironmentVariableAccess")).to include("Enabled" => true)
    end
  end

  describe "Rails.env and ENV checks in application code" do
    subject(:offenses) do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".rubocop.yml"), <<~YAML)
          plugins:
            - rubocop-powerhome
          AllCops:
            NewCops: disable
            SuggestExtensions: false
        YAML
        files.each do |path|
          FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
          File.write(File.join(dir, path), source)
        end
        run_rubocop(dir)
      end
    end

    let(:source) do
      <<~RUBY
        # frozen_string_literal: true

        module MyComponent
          def self.call
            return ENV.fetch("FEATURE", nil) if Rails.env.production?

            Rails.env.local?
          end
        end
      RUBY
    end

    let(:files) do
      %w[
        components/my_component/app/models/my_component/thing.rb
        components/my_component/lib/my_component/thing.rb
        components/my_component/lib/tasks/thing.rake
        components/my_component/config/initializers/thing.rb
        components/my_component/config/environments/production.rb
        components/my_component/spec/thing_spec.rb
        Gemfile
      ]
    end

    def run_rubocop(dir)
      output = File.join(dir, "offenses.json")
      RuboCop::CLI.new.run(["--config", File.join(dir, ".rubocop.yml"), "--cache", "false",
                            "--format", "json", "--out", output, dir])
      JSON.parse(File.read(output))["files"].to_h do |file|
        cops = file["offenses"].map { |offense| offense["cop_name"] }
        [file["path"].delete_prefix("#{dir}/"), cops.grep(%r{\ARails/Env}).sort]
      end
    end

    it "flags Rails.env predicates and ENV reads under app/ and lib/" do
      expect(offenses).to include(
        "components/my_component/app/models/my_component/thing.rb" => %w[Rails/Env Rails/EnvironmentVariableAccess],
        "components/my_component/lib/my_component/thing.rb" => %w[Rails/Env Rails/EnvironmentVariableAccess]
      )
    end

    it "flags Rails.env, but not ENV, in rake tasks, where ENV holds command-line arguments" do
      expect(offenses).to include("components/my_component/lib/tasks/thing.rake" => %w[Rails/Env])
    end

    it "allows both in the config layer, specs and the Gemfile" do
      %w[
        components/my_component/config/initializers/thing.rb
        components/my_component/config/environments/production.rb
        components/my_component/spec/thing_spec.rb
        Gemfile
      ].each do |path|
        expect(offenses.fetch(path, [])).to be_empty, "expected no Rails.env or ENV offenses in #{path}"
      end
    end
  end
end
