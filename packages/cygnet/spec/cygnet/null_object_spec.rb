# frozen_string_literal: true

require "spec_helper"

describe Cygnet::NullObject do
  subject { Cygnet::NullObject.new }

  it "responds to a random method call with another instance of itself" do
    expect(subject.random_method).to be_a(Cygnet::NullObject)
  end

  it "reports that it responds to a random method" do
    expect(subject).to respond_to(:random_method)
  end

  it "allows for the use of an ||" do
    expect(!!subject ? subject : "foo").to eql("foo") # rubocop:disable Style/DoubleNegation
  end

  it "subject should be considered to be naught" do
    expect(!subject).to be true
  end

  it "subject should be considered to be nil" do
    expect(subject.nil?).to be true
  end

  it "subject should be considered to be blank" do
    expect(subject.blank?).to be true
  end

  it "casts to an empty string correctly" do
    expect(subject.to_s).to eql("")
  end

  it "casts to an integer correctly" do
    expect(subject.to_i).to eql(0)
  end

  it "casts to a float correctly" do
    expect(subject.to_f).to eql(0.0)
  end

  it "casts to an array correctly" do
    expect(subject.to_a).to eql([])
    expect(subject.to_ary).to eql([])
  end

  it "casts to a hash correctly" do
    expect(subject.to_h).to eql({})
    expect(subject.to_hash).to eql({})
  end

  it "casts to a complex number correctly" do
    expect(subject.to_c).to eql(Complex(0))
  end

  it "maps to a rational number correctly" do
    expect(subject.to_r).to eql(Rational(0))
  end
end
