# frozen_string_literal: true

require "spec_helper"

describe Naughty::DeepStruct do
  describe "created empty" do
    subject { Naughty::DeepStruct.new }

    it "returns a NullObject for any method call" do
      expect(subject.random).to be_a(Naughty::NullObject)
    end
  end

  describe "created from existing data" do
    subject { Naughty::DeepStruct.new(foo: :bar, baz: { do: :re }) }

    it "allows access to the data" do
      expect(subject.foo).to eql(:bar)
    end

    it "allows access to nested data" do
      expect(subject.baz.do).to eql(:re)
    end

    it "returns a NullObject for any missing data" do
      expect(subject.random).to be_a(Naughty::NullObject)
    end

    it "reports that it responds to a random method" do
      expect(subject).to respond_to(:random_method)
    end
  end
end
