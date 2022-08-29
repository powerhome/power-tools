# frozen_string_literal: true

require "spec_helper"

RSpec.describe NitroConfig::Options do
  subject do
    described_class.new(
      simple: "value",
      complex: {
        config: "YUP",
        with: {
          parent: "yeah",
        },
      }
    )
  end

  describe ".load_yml(file, environment)" do
    let(:config_file) { File.expand_path("../../config/config.yml", __dir__) }
    subject { NitroConfig::Options.load_yml(config_file, "development") }

    it "parses a yml file" do
      expect(subject.get("key/nested/value")).to eql "Hello World"
    end

    it "parses a ERb from the YAML" do
      expect(subject.get("another/config")).to eql "vrum vrum vrum vrum vrum vrum vrum vrum vrum vrum"
    end
  end

  describe "[]" do
    it "is a hash with indifferent access" do
      expect(subject).to be_a(HashWithIndifferentAccess)
    end
  end

  describe "#preserve!" do
    it "preserves the config after any changes made in the passed block" do
      subject.preserve! do
        subject[:simple] = "another value"
        expect(subject[:simple]).to eql "another value"
      end
      expect(subject[:simple]).to eql "value"
    end
  end

  describe "#get" do
    it "allows boolean false value" do
      subject[:some] = { config: false }

      expect(subject.get("some/config", true)).to be false
    end

    it "gets the configuration via the path when it exists" do
      expect(subject.get("simple")).to eql "value"
      expect(subject.get("complex/config")).to eql "YUP"
      expect(subject.get("complex/with/parent")).to eql "yeah"
    end

    it "returns the default when the configuration does not exist and one is provided" do
      expect(subject.get("lol", "lulz")).to eql "lulz"
    end

    it "accepts array paths" do
      expect(subject.get(%w[complex with parent])).to eql "yeah"
    end

    it "is nil when the config does not exist" do
      expect(subject.get("lol")).to be_nil
    end

    it "is nil when a parent config does not exist" do
      expect(subject.get("lol/config")).to be_nil
    end

    it "is nil when a parent config does not exist" do
      expect(subject.get("complex/lol/parent")).to be_nil
    end
  end

  describe "#get!" do
    it "raises an error when the config does not exist" do
      expect { subject.get!("lol") }.to raise_error(
        "lol not found in app config! If you're working in development, you probably need to" \
        "`cp config/config_sample.yml config/config.yml` or create a symlink for convenience."
      )
    end
  end
end
