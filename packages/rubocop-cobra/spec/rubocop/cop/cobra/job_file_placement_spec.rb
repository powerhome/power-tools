# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::JobFilePlacement do
  subject(:cop) { described_class.new }

  context "does not register an offense" do
    let(:source) { "contents_of_file_do_not_matter_when_no_offense" }

    it "when linting a file not in app/jobs/" do
      random_file = "root/bar/random.rb"

      expect_no_offenses(source, random_file)
    end

    it "when job is correctly namespaced" do
      file_path = "root/components/my_component/app/jobs/my_component/foo_job.rb"

      expect_no_offenses(source, file_path)
    end
  end

  context "registers an offense" do
    it "when job is defined directly inside app/jobs/" do
      source = <<~RUBY
        class FooJob
        ^^^^^^^^^^^^ Do not add top-level files into `app/jobs/`. Namespace them like `app/jobs/my_component/foo_job.rb`
        end
      RUBY

      file_path = "components/my_component/app/jobs/foo_job.rb"

      expect_offense(source, file_path)
    end

    it "when job is defined directly inside mismatched subdirectory of app/jobs/" do
      source = <<~RUBY
        class FooJob
        ^^^^^^^^^^^^ Do not add top-level files into `app/jobs/`. Namespace them like `app/jobs/my_component/other_namespace/foo_job.rb`
        end
      RUBY

      file_path = "components/my_component/app/jobs/other_namespace/foo_job.rb"

      expect_offense(source, file_path)
    end
  end
end
