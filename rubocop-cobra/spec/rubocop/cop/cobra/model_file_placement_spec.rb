# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::ModelFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/models/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when model is correctly namespaced" do
      file_path = "root/components/my_component/app/models/my_component/foo.rb"

      expect_no_offenses(source, file_path)
    end

    it "when model is correctly namespaced with concerns" do
      file_path = "root/components/my_component/app/models/concerns/my_component/foo.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when model is defined directly inside app/models/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/models/`. Namespace them like `app/models/my_component/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/models/foo.rb"

      expect_offense(source, file_path)
    end

    it "when model is defined directly inside mismatched subdirectory of app/models/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/models/`. Namespace them like `app/models/my_component/other_namespace/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/models/other_namespace/foo.rb"

      expect_offense(source, file_path)
    end

    it "when file is directly inside a concerns directory inside of app/models/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/models/concerns/`. Namespace them like `app/models/concerns/my_component/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/models/concerns/foo.rb"

      expect_offense(source, file_path)
    end
  end
end
