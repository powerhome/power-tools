# frozen_string_literal: true

require "spec_helper"

RSpec.describe Stagecoach::Config do
  let(:base_config) do
    {
      server: "http://trino.example.com",
      user: "ada",
      catalog: "warehouse",
      schema: "public",
    }
  end

  describe ".client_options" do
    it "fills in default timeouts" do
      options = described_class.client_options(base_config)
      expect(options[:query_timeout]).to eq(60)
      expect(options[:plan_timeout]).to eq(10)
    end

    it "preserves caller-supplied timeouts" do
      options = described_class.client_options(base_config.merge(query_timeout: 5))
      expect(options[:query_timeout]).to eq(5)
    end

    it "accepts string keys (as database.yml usually provides)" do
      string_keyed = base_config.transform_keys(&:to_s)
      expect { described_class.client_options(string_keyed) }.not_to raise_error
    end

    it "raises when a required key is missing" do
      expect { described_class.client_options(base_config.except(:user)) }
        .to raise_error(Stagecoach::ConfigurationError, /user/)
    end
  end

  describe ".slow_query_threshold" do
    it "defaults to 5.0 seconds" do
      expect(described_class.slow_query_threshold(base_config)).to eq(5.0)
    end

    it "respects an explicit threshold" do
      expect(described_class.slow_query_threshold(base_config.merge(slow_query_threshold_seconds: 0.25)))
        .to eq(0.25)
    end
  end
end
