# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::GraphQL::RootTypesInBlock, :config do
  context "when root type is configured without a block" do
    it "registers an offense for query" do
      expect_offense(<<~RUBY)
        query Types::Query
        ^^^^^^^^^^^^^^^^^^ type configuration can be moved to a block to defer loading the type's file
      RUBY
    end

    it "registers an offense for mutation" do
      expect_offense(<<~RUBY)
        mutation Types::Mutation
        ^^^^^^^^^^^^^^^^^^^^^^^ type configuration can be moved to a block to defer loading the type's file
      RUBY
    end

    it "registers an offense for subscription" do
      expect_offense(<<~RUBY)
        subscription Types::Subscription
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ type configuration can be moved to a block to defer loading the type's file
      RUBY
    end
  end

  context "when root type is configured with a block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        query { Types::Query }
      RUBY
    end

    it "does not register an offense for mutation with block" do
      expect_no_offenses(<<~RUBY)
        mutation { Types::Mutation }
      RUBY
    end
  end
end
