# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::DependencyVersion do
  subject(:cop) { described_class.new }

  before { allow(cop).to receive(:nitro_components).and_return(["nitro_component"]) }

  context "#add_dependency" do
    context "registers offense" do
      it "when a dependency is declared without a version" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_dependency "outside_lib"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ External component dependencies should be declared with a version
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_offense(source, file_path)
      end
    end

    context "does not register offenses" do
      it "when dependency is versioned" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_dependency "some_lib", "1.0.1"
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_no_offenses(source, file_path)
      end
    end
  end

  context "#add_development_dependency" do
    context "registers offense" do
      it "when an external dependency is declared without a version" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_development_dependency "outside_lib"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ External component dependencies should be declared with a version
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_offense(source, file_path)
      end
    end

    context "does not register offenses" do
      it "when external dependency is versioned" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_development_dependency "some_lib", "4.3.56"
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_no_offenses(source, file_path)
      end
    end
  end

  context "#add_runtime_dependency" do
    context "registers offense" do
      it "when an external dependency is declared without a version" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_runtime_dependency "some_lib"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ External component dependencies should be declared with a version
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_offense(source, file_path)
      end
    end

    context "does not register offenses" do
      it "when external dependency is versioned" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_runtime_dependency "some_lib", "1.6.3"
          end
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_no_offenses(source, file_path)
      end
    end
  end

  context "all dependency methods" do
    context "do not register offenses" do
      it "when file does not end in .gemspec" do
        source = <<~RUBY
          Gem::Specification.new do |s|
            s.add_dependency "some_lib"
          end
        RUBY

        file_path = "/components/my_component/my_component.anything"

        expect_no_offenses(source, file_path)
      end

      it "when not invoked within a block" do
        source = <<~RUBY
          s.add_development_dependency "some_lib"
        RUBY

        file_path = "/components/my_component/my_component.gemspec"

        expect_no_offenses(source, file_path)
      end
    end
  end
end
