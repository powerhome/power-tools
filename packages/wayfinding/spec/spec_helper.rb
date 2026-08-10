# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "wayfinding"
require "pry-byebug"

require_relative "support/fake_engine"

RSpec.configure do |config|
  if ENV["CI"]
    config.before(:example, :focus) { raise "Should not commit focused specs" }
  else
    config.filter_run :focus
    config.run_all_when_everything_filtered = true
  end
  config.warnings = false

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.mock_with(:rspec) { |mocks| mocks.syntax = :expect }

  config.before { Wayfinding.reset! }
end
