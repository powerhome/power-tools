# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::EngineIsolateNamespace do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    it "when the engine isolates its namespace" do
      expect_no_offenses(<<~RUBY)
        module MyComponent
          class Engine < ::Rails::Engine
            isolate_namespace MyComponent

            config.generators.api_only = true
          end
        end
      RUBY
    end

    it "when the engine inherits from Rails::Engine without a leading ::" do
      expect_no_offenses(<<~RUBY)
        module MyComponent
          class Engine < Rails::Engine
            isolate_namespace MyComponent
          end
        end
      RUBY
    end

    it "when isolate_namespace is called later in the body, with parentheses or with a leading ::" do
      expect_no_offenses(<<~RUBY)
        module MyComponent
          class Engine < ::Rails::Engine
            config.autoload_paths << root.join("lib")
            isolate_namespace(::MyComponent)
          end
        end
      RUBY
    end

    it "when the engine is defined with a compact name" do
      expect_no_offenses(<<~RUBY)
        class MyComponent::Engine < ::Rails::Engine
          isolate_namespace MyComponent
        end
      RUBY
    end

    it "when the engine is nested in several modules" do
      expect_no_offenses(<<~RUBY)
        module MyComponent
          module Admin
            class Engine < ::Rails::Engine
              isolate_namespace MyComponent::Admin
            end
          end
        end
      RUBY
    end

    it "when the namespace is a class" do
      expect_no_offenses(<<~RUBY)
        class SpeechRecognition
          class Engine < ::Rails::Engine
            isolate_namespace SpeechRecognition
          end
        end
      RUBY
    end

    it "when the engine has no namespace" do
      expect_no_offenses(<<~RUBY)
        class Engine < ::Rails::Engine
        end
      RUBY
    end

    it "when the class is not a Rails engine" do
      expect_no_offenses(<<~RUBY)
        module MyComponent
          class Railtie < ::Rails::Railtie
          end

          class Engine < Other::Engine
          end
        end
      RUBY
    end
  end

  context "registers an offense" do
    it "when the engine does not call isolate_namespace" do
      expect_offense(<<~RUBY)
        module MyComponent
          class Engine < ::Rails::Engine
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Call `isolate_namespace MyComponent` in the engine.
            config.generators.api_only = true
          end
        end
      RUBY
    end

    it "when the engine body is empty" do
      expect_offense(<<~RUBY)
        module MyComponent
          class Engine < Rails::Engine; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Call `isolate_namespace MyComponent` in the engine.
        end
      RUBY
    end

    it "when isolate_namespace is only called inside a block" do
      expect_offense(<<~RUBY)
        module MyComponent
          class Engine < ::Rails::Engine
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Call `isolate_namespace MyComponent` in the engine.
            initializer "my_component.isolate" do
              isolate_namespace MyComponent
            end
          end
        end
      RUBY
    end

    it "when a compact engine does not call isolate_namespace" do
      expect_offense(<<~RUBY)
        class MyComponent::Admin::Engine < ::Rails::Engine
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Call `isolate_namespace MyComponent::Admin` in the engine.
        end
      RUBY
    end

    it "when the engine isolates a different namespace" do
      expect_offense(<<~RUBY)
        module MyComponent
          class Engine < ::Rails::Engine
            isolate_namespace OtherComponent
                              ^^^^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Isolate the engine in its own namespace, `MyComponent`.
          end
        end
      RUBY
    end

    it "when a nested engine isolates only the outer namespace" do
      expect_offense(<<~RUBY)
        module MyComponent
          module Admin
            class Engine < ::Rails::Engine
              isolate_namespace MyComponent
                                ^^^^^^^^^^^ Cobra/EngineIsolateNamespace: Isolate the engine in its own namespace, `MyComponent::Admin`.
            end
          end
        end
      RUBY
    end
  end
end
