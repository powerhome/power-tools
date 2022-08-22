# frozen_string_literal: true

require "rails_helper"

class AnotherClass # rubocop:disable Lint/EmptyClass
end

class ManyThings # rubocop:disable Lint/EmptyClass
end

module MyModule
  class MyClass # rubocop:disable Lint/EmptyClass
  end
end

describe Consent::SubjectCoder do
  describe ".load" do
    it "returns nil when no key is given" do
      expect(Consent::SubjectCoder.load(nil)).to be_nil
    end

    it "loads classes from a snake case string" do
      expect(Consent::SubjectCoder.load("another_class")).to be AnotherClass
    end

    it "loads symbols from a snake case string" do
      expect(Consent::SubjectCoder.load("beta")).to be :beta
    end

    it "supports modularized names" do
      expect(Consent::SubjectCoder.load("my_module/my_class")).to be MyModule::MyClass
    end

    it "supports plural class names" do
      expect(Consent::SubjectCoder.load("many_things")).to be ManyThings
    end

    it "does not consider modules as a valid subject" do
      expect(Consent::SubjectCoder.load("my_module")).to be :my_module
    end
  end

  describe ".dump" do
    it "dumps classes to a snake case string" do
      expect(Consent::SubjectCoder.dump(AnotherClass)).to eql "another_class"
    end

    it "dumps symbols to a snake case string" do
      expect(Consent::SubjectCoder.dump(:beta)).to eql "beta"
    end

    it "supports modularized names" do
      expect(Consent::SubjectCoder.dump(MyModule::MyClass)).to eql "my_module/my_class"
    end
  end
end
