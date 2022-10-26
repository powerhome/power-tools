# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::PresenterFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/presenters/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when presenter is correctly namespaced" do
      file_path = "root/components/my_component/app/presenters/my_component/foo_presenter.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when presenter is defined directly inside app/presenters/" do
      source = <<~RUBY
        class FooPresenter
        ^^^^^^^^^^^^^^^^^^ Do not add top-level files into `app/presenters/`. Namespace them like `app/presenters/my_component/foo_presenter.rb`
        end
      RUBY

      file_path = "components/my_component/app/presenters/foo_presenter.rb"

      expect_offense(source, file_path)
    end

    it "when presenter is defined directly inside mismatched subdirectory of app/presenters/" do
      source = <<~RUBY
        class FooPresenter
        ^^^^^^^^^^^^^^^^^^ Do not add top-level files into `app/presenters/`. Namespace them like `app/presenters/my_component/other_namespace/foo_presenter.rb`
        end
      RUBY

      file_path = "components/my_component/app/presenters/other_namespace/foo_presenter.rb"

      expect_offense(source, file_path)
    end
  end
end
