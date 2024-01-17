# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Tooling::UnsupportedClient do
  subject(:cop) { described_class.new }

  context "when using Faraday" do
    let(:source) do
      <<~RUBY
        class Foo
          def bar
            Faraday.get("https://example.com")
          end
        end
      RUBY
    end

    it "registers an offense when Faraday is used" do
      expect_offenses(source)
    end
  end
end
