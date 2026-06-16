# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::GraphQL::DefaultRequiredTrue, :config do
  context "when `required: true` is explicitly set on an argument" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        argument :id, ID, required: true
                          ^^^^^^^^^^^^^^ `required: true` is the default and can be removed.
      RUBY
    end

    it "does not register an offense when required is omitted" do
      expect_no_offenses(<<~RUBY)
        argument :id, ID
      RUBY
    end

    it "does not register an offense when required: false" do
      expect_no_offenses(<<~RUBY)
        argument :id, ID, required: false
      RUBY
    end
  end
end
