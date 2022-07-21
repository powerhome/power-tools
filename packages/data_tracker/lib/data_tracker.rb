# frozen_string_literal: true

require_relative "data_tracker/dsl"
require_relative "data_tracker/model_helper"
require_relative "data_tracker/railtie" if defined?(Rails)
require_relative "data_tracker/tracker"
require_relative "data_tracker/version"

# :nodoc
module DataTracker
  # :nodoc
  class Error < StandardError; end

  def self.trackers
    @trackers ||= {}
  end

  def self.setup(&block)
    ::DataTracker::DSL.build(&block)
  end

  def self.apply(model, overrides = {})
    @trackers.each do |key, tracker|
      tracker.apply(model, overrides.fetch(key, {}))
    end
  end
end
