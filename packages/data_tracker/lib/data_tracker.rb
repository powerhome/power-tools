# frozen_string_literal: true

require_relative "data_tracker/dsl"
require_relative "data_tracker/model_helper"
require_relative "data_tracker/railtie" if defined?(Rails)
require_relative "data_tracker/tracker"
require_relative "data_tracker/version"

# DataTracker helps you centralize data tracking configuration to be used accross
# different models
module DataTracker
  # Trackers setup in DataTracker
  #
  # @return [Hash<Symbol,::DataTracker::Tracker>]
  #
  def self.trackers
    @trackers ||= {}
  end

  # Setup a DataTracker::Tracker
  #
  # TODO: write documentation
  #
  def self.setup(&block)
    ::DataTracker::DSL.build(&block)
  end

  # Applies all trackers to a given model
  #
  def self.apply(model, overrides = {})
    @trackers.each do |key, tracker|
      tracker.apply(model, overrides.fetch(key, {}))
    end
  end
end
