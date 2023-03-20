# frozen_string_literal: true

require "pry-byebug"

RSpec.configure do |config|
  if ENV["CI"]
    config.before(:example, :focus) { raise "Should not commit focused specs" }
  else
    config.filter_run :focus
    config.run_all_when_everything_filtered = true
  end
  config.warnings = false

  config.default_formatter = "doc" if config.files_to_run.one?

  # DatabaseCleaner configuration
  require "database_cleaner"
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = :expect
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = false
  end
end

# This is a provisional fix for an rspec-rails issue
# (see https://github.com/rspec/rspec-rails/issues/476).
# It allows for a proper test execution with `config.threadsafe!`.
#
# ActionView::TestCase::TestController.instance_eval do
#   helper Rails.application.routes.url_helpers#, (append other helpers you need)
# end
# ActionView::TestCase::TestController.class_eval do
#   def _routes
#     Rails.application.routes
#   end
# end
