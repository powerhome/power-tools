# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::ControllerFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/controllers/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when controller is correctly namespaced" do
      file_path = "root/components/my_component/app/controllers/my_component/foo_controller.rb"

      expect_no_offenses(source, file_path)
    end

    it "when controller is correctly namespaced with concerns" do
      file_path = "root/components/my_component/app/controllers/concerns/my_component/foo.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when controller is defined directly inside app/controllers/" do
      source = <<~RUBY
        class FooController
        ^^^^^^^^^^^^^^^^^^^ Do not add top-level files into `app/controllers/`. Namespace them like `app/controllers/my_component/foo_controller.rb`
        end
      RUBY

      file_path = "components/my_component/app/controllers/foo_controller.rb"

      expect_offense(source, file_path)
    end

    it "when controller is defined inside a different subdirectory of app/controllers/" do
      source = <<~RUBY
        class FooController
        ^^^^^^^^^^^^^^^^^^^ Do not add top-level files into `app/controllers/`. Namespace them like `app/controllers/my_component/other_namespace/foo_controller.rb`
        end
      RUBY

      file_path = "components/my_component/app/controllers/other_namespace/foo_controller.rb"

      expect_offense(source, file_path)
    end

    it "when file is directly inside a concerns directory inside app/controllers/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/controllers/concerns/`. Namespace them like `app/controllers/concerns/my_component/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/controllers/concerns/foo.rb"

      expect_offense(source, file_path)
    end
  end
end
