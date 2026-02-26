# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::GraphQL::FieldTypeInBlock, :config do
  context "when field type is given inline (custom type)" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        field :thing, Types::Thing
                      ^^^^^^^^^^^ type configuration can be moved to a block to defer loading the type's file
      RUBY
    end
  end

  context "when field type is in a block with type()" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        field :thing do
          type(Types::Thing)
        end
      RUBY
    end
  end

  context "when field uses a built-in scalar" do
    it "does not register an offense for String" do
      expect_no_offenses(<<~RUBY)
        field :name, String
      RUBY
    end

    it "does not register an offense for Int" do
      expect_no_offenses(<<~RUBY)
        field :count, Int
      RUBY
    end

    it "does not register an offense for ID" do
      expect_no_offenses(<<~RUBY)
        field :id, ID
      RUBY
    end

    it "does not register an offense for Boolean" do
      expect_no_offenses(<<~RUBY)
        field :active, Boolean
      RUBY
    end

    it "does not register an offense for Float" do
      expect_no_offenses(<<~RUBY)
        field :price, Float
      RUBY
    end
  end
end
