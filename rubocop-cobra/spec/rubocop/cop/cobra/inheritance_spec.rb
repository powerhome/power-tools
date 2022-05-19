# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::Inheritance do
  subject(:cop) { described_class.new }

  it "accepts modularized ApplicationController inheritance" do
    expect_no_offenses(<<~RUBY)
      class FooController < MyComponent::ApplicationController
      end
    RUBY
  end

  it "registers an offense when inheriting from ApplicationController" do
    expect_offense(<<-RUBY)
      class FooController < ApplicationController
                            ^^^^^^^^^^^^^^^^^^^^^ Do not directly inherit from a global ApplicationController. Instead, inherit from your component's modularized ApplicationController, such as MyComponent::ApplicationController.
      end
    RUBY
  end

  it "accepts modularized ApplicationRecord inheritance" do
    expect_no_offenses(<<~RUBY)
      class Foo < MyComponent::ApplicationRecord
      end
    RUBY
  end

  it "registers an offense when inheriting from ApplicationRecord" do
    expect_offense(<<-RUBY)
      class Foo < ApplicationRecord
                  ^^^^^^^^^^^^^^^^^ Do not directly inherit from a global ApplicationRecord. Instead, inherit from your component's modularized ApplicationRecord, such as MyComponent::ApplicationRecord.
      end
    RUBY
  end

  it "accepts modularized ApiController inheritance" do
    expect_no_offenses(<<~RUBY)
      class FooController < MyComponent::ApiController
      end
    RUBY
  end

  it "registers an offense when inheriting from ApiController" do
    expect_offense(<<-RUBY)
      class FooController < ApiController
                            ^^^^^^^^^^^^^ Do not directly inherit from a global ApiController. Instead, inherit from your component's modularized ApiController, such as MyComponent::ApiController.
      end
    RUBY
  end
end
