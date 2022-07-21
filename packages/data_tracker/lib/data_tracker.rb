# frozen_string_literal: true

require_relative "data_tracker/dsl"
require_relative "data_tracker/version"
require_relative "data_tracker/tracker"

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

  def self.apply(model)
    @trackers.each do |_key, tracker|
      tracker.apply(model)
    end
  end
end
