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

    context "when server is a URL with a scheme prefix" do
      it "strips https:// and sets ssl: true" do
        options = described_class.client_options(base_config.merge(server: "https://trino.example.com:8443"))
        expect(options[:server]).to eq("trino.example.com:8443")
        expect(options[:ssl]).to be true
      end

      it "strips http:// and sets ssl: false" do
        options = described_class.client_options(base_config.merge(server: "http://trino.example.com:8090"))
        expect(options[:server]).to eq("trino.example.com:8090")
        expect(options[:ssl]).to be false
      end

      it "lets an explicit ssl override the inferred value" do
        options = described_class.client_options(
          base_config.merge(server: "https://trino.example.com:8443", ssl: false)
        )
        expect(options[:ssl]).to be false
      end

      it "leaves a bare host:port server untouched" do
        options = described_class.client_options(base_config.merge(server: "trino.example.com:8090"))
        expect(options[:server]).to eq("trino.example.com:8090")
        expect(options).not_to have_key(:ssl)
      end
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
