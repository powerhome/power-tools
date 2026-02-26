# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::GraphQL::DefaultNullTrue, :config do
  context "when `null: true` is explicitly set on a field" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        field :name, String, null: true
                              ^^^^^^^^^^ `null: true` is the default and can be removed.
      RUBY
    end

    it "does not register an offense when null is omitted" do
      expect_no_offenses(<<~RUBY)
        field :name, String
      RUBY
    end

    it "does not register an offense when null: false" do
      expect_no_offenses(<<~RUBY)
        field :name, String, null: false
      RUBY
    end
  end
end
