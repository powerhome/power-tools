# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::ViewComponentFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/components/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when view_component is correctly namespaced" do
      file_path = "root/components/my_component/app/components/my_component/resource/foo_component.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when view_component is defined directly inside app/components/" do
      source = <<~RUBY
        class FooComponent
        ^^^^^^^^^^^^^^^^^^ Nest ViewComponent definitions in the parent component and resource namespace. For example: `app/components/my_component/<resource>/foo_component.rb`
        end
      RUBY

      file_path = "components/my_component/app/components/foo_component.rb"

      expect_offense(source, file_path)
    end

    it "when view_component is defined directly inside mismatched subdirectory of app/components/" do
      source = <<~RUBY
        class FooComponent
        ^^^^^^^^^^^^^^^^^^ Nest ViewComponent definitions in the parent component and resource namespace. For example: `app/components/my_component/<resource>/foo_component.rb`
        end
      RUBY

      file_path = "components/my_component/app/components/other_namespace/resource/foo_component.rb"

      expect_offense(source, file_path)
    end

    it "when view_component is defined directly inside mismatched subdirectory of app/components/" do
      source = <<~RUBY
        class FooComponent
        ^^^^^^^^^^^^^^^^^^ Nest ViewComponent definitions in the parent component and resource namespace. For example: `app/components/my_component/<resource>/foo_component.rb`
        end
      RUBY

      file_path = "components/my_component/app/components/other_namespace/resource/foo_component.rb"

      expect_offense(source, file_path)
    end

    it "when view_component is defined within directory of component name, but not in an additional subdirectory" do
      source = <<~RUBY
        module MyComponent
        ^^^^^^^^^^^^^^^^^^ Nest ViewComponent definitions in the parent component and resource namespace. For example: `app/components/my_component/<resource>/foo_component.rb`
          class FooComponent
          end
        end
      RUBY

      file_path = "components/my_component/app/components/my_component/foo_component.rb"

      expect_offense(source, file_path)
    end
  end
end
