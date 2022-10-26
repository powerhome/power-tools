# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::LibFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when file is not in lib/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when file is correctly namespaced" do
      file_path = "root/components/my_component/lib/my_component/foo.rb"

      expect_no_offenses(source, file_path)
    end

    it "when file is in lib/tasks/" do
      file_path = "components/my_component/lib/tasks/foo.rb"

      expect_no_offenses(source, file_path)
    end

    it "when file is the name of the component" do
      file_path = "components/my_component/lib/my_component.rb"

      expect_no_offenses(source, file_path)
    end

    it "when lib directory is inside the spec directory" do
      file_path = "components/my_component/spec/lib/foo_spec.rb"

      expect_no_offenses(source, file_path)
    end

    it "when file is not in a component" do
      file_path = "nitro-web/lib/foo.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when lib file is defined directly inside lib/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `lib/`. Namespace them like `lib/awesome_component/foo.rb`
        end
      RUBY

      file_path = "components/awesome_component/lib/foo.rb"

      expect_offense(source, file_path)
    end

    it "when lib file is defined inside a different subdirectory of lib/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `lib/`. Namespace them like `lib/my_component/other_namespace/my_file.rb`
        end
      RUBY

      file_path = "components/my_component/lib/other_namespace/my_file.rb"

      expect_offense(source, file_path)
    end
  end
end
