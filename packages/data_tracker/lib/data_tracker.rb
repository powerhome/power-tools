# frozen_string_literal: true

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
    ::DataTracker::Builder.module_eval(&block)
  end

  def self.apply(model)
    @trackers.each do |_key, tracker|
      tracker.apply(model)
    end
  end

  # :nodoc
  module Builder
  module_function

    def tracker(key, &block)
      DataTracker.trackers[key] = Tracker.new(&block)
    end
  end
end
