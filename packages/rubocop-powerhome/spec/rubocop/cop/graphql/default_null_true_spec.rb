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

    it "registers an offense when `null: true` follows other keywords" do
      expect_offense(<<~RUBY)
        field :name, String, description: "Name", null: true
                                                  ^^^^^^^^^^ `null: true` is the default and can be removed.
      RUBY

      expect_correction(<<~RUBY)
        field :name, String, description: "Name"
      RUBY
    end

    it "registers an offense when `null: true` is between other keywords" do
      expect_offense(<<~RUBY)
        field :name, String, description: "Name", null: true, method: :full_name
                                                  ^^^^^^^^^^ `null: true` is the default and can be removed.
      RUBY

      expect_correction(<<~RUBY)
        field :name, String, description: "Name", method: :full_name
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
