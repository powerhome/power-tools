# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Naming::ViewComponent do
  subject(:cop) { described_class.new }

  it "accepts view_component classes ending with 'Component'" do
    expect_no_offenses(<<~RUBY)
      class FooComponent < MyComponent::ApplicationComponent
      end
    RUBY
  end

  it "does not register offense for class that do not inherit from ApplicationComponent or ViewComponent::Base" do
    expect_no_offenses(<<~RUBY)
      class Foo < ApplicationRecord
      end
    RUBY
  end

  it "registers an offense when class does not end with component" do
    expect_offense(<<-RUBY)
      class Foo < MyComponent::ApplicationComponent
            ^^^ End ViewComponent classnames with 'Component'
      end
    RUBY
  end

  it "registers an offense when class does not end with component" do
    expect_offense(<<-RUBY)
      class Foo < ::ViewComponent::Base
            ^^^ End ViewComponent classnames with 'Component'
      end
    RUBY
  end
end
