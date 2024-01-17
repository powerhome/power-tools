# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Tooling::UnsupportedClient do
  subject(:cop) { described_class.new }

  shared_examples "making HTTP calls for" do |key, http_class|
    context "when using #{http_class}" do
      let(:source) do
        <<~RUBY
          class Foo
            def bar
            ^^^^^^^ Tooling/UnsupportedClient: Found #{key}! Please use `Net::HTTP` instead.
              #{http_class}.get("https://example.com")
            end
          end
        RUBY
      end

      it "registers an offense" do
        expect_offense(source)
      end
    end
  end

  context "when using Net::HTTP" do
    let(:source) do
      <<~RUBY
        class Foo
          def bar
            # Invalid API doesn't matter here, we just care about not triggering the cop
            Net::HTTP.get("https://example.com")
          end
        end
      RUBY
    end

    it "registers an offense when Net::HTTP is used" do
      expect_no_offenses(source)
    end
  end

  it_behaves_like "making HTTP calls for", :faraday, "Faraday"
  it_behaves_like "making HTTP calls for", :httparty, "HTTParty"
  it_behaves_like "making HTTP calls for", :rest_client, "RestClient"
  it_behaves_like "making HTTP calls for", :typhoeus, "Typhoeus"
  it_behaves_like "making HTTP calls for", :http_client, "HTTPClient"
end
