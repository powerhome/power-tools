# frozen_string_literal: true

require 'ruby_test_helpers/factory_bot_helper'
require 'active_job'

module RubyTestHelpers
  # Your code goes here...
end

RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
RSpec::Expectations.configuration.on_potential_false_positives = :raise

RSpec.configure do |config|
  include ActiveJob::TestHelper

  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end

ActiveJob::Base.queue_adapter = :test
