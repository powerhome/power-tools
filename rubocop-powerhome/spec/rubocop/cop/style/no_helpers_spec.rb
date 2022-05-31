# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Style::NoHelpers do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/helpers/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end
  end

  context "registers an offense" do
    it "when file exists inside app/helpers/" do
      source = <<~RUBY
        class FooHelper
        ^^^^^^^^^^^^^^^ Helpers create global view methods. Instead, use view objects to encapsulate your display logic.
        end
      RUBY

      file_path = "app/helpers/foo_helper.rb"

      expect_offense(source, file_path)
    end
  end
end
