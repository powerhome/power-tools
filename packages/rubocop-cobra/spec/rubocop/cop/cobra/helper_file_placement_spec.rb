# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::HelperFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/helpers/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when helper is correctly namespaced" do
      file_path = "root/components/my_component/app/helpers/my_component/foo.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when helper is defined directly inside app/helpers/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/helpers/`. Namespace them like `app/helpers/my_component/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/helpers/foo.rb"

      expect_offense(source, file_path)
    end

    it "when helper is defined inside a different subdirectory of app/helpers/" do
      source = <<~RUBY
        class Foo
        ^^^^^^^^^ Do not add top-level files into `app/helpers/`. Namespace them like `app/helpers/my_component/other_namespace/foo.rb`
        end
      RUBY

      file_path = "components/my_component/app/helpers/other_namespace/foo.rb"

      expect_offense(source, file_path)
    end
  end
end
