# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::GemRequirement do
  subject(:cop) { described_class.new }

  it "accepts component gem dependencies that specify required: nil" do
    expect_no_offenses(<<~RUBY)
      source "https://rubygems.org"

      path ".." do
        gem "nitro_component", require: nil
      end
    RUBY
  end

  it "accepts component gem dependencies that specify required: false" do
    expect_no_offenses(<<~RUBY)
      source "https://rubygems.org"

      path ".." do
        gem "nitro_component", require: false
      end
    RUBY
  end

  it "ignores non-component gem dependencies" do
    expect_no_offenses(<<~RUBY)
      source "https://rubygems.org"

      gem "foo"
    RUBY
  end

  it "accepts valid component gem dependencies mixed with Ruby comments" do
    expect_no_offenses(<<~RUBY)
      source "https://rubygems.org"

      path ".." do
        # Dependencies on other components go here
        gem "nitro_component", require: nil
      end
    RUBY
  end

  it "accepts valid component gem dependencies using old hash syntax" do
    expect_no_offenses(<<~RUBY)
      source "https://rubygems.org"

      path ".." do
        gem "nitro_component", :require => nil
      end
    RUBY
  end

  context "registers an offense for component gem dependencies that are required" do
    it "when explicitly specified" do
      expect_offense(<<~RUBY)
        source "https://rubygems.org"

        path ".." do
          gem "nitro_component", require: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Component Gemfile dependencies must specify 'require: nil'.
        end
      RUBY
    end

    it "when not explicitly specified" do
      expect_offense(<<~RUBY)
        source "https://rubygems.org"

        path ".." do
          gem "nitro_component"
          ^^^^^^^^^^^^^^^^^^^^^ Component Gemfile dependencies must specify 'require: nil'.
        end
      RUBY
    end

    it "when mixed with valid declarations" do
      expect_offense(<<~RUBY)
        source "https://rubygems.org"

        path ".." do
          # Dependencies on other components go here
          gem "nitro_component", require: nil
          gem "other_component"
          ^^^^^^^^^^^^^^^^^^^^^ Component Gemfile dependencies must specify 'require: nil'.
          gem "another_component", require: nil
        end
      RUBY
    end
  end
end
