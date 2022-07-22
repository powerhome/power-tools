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

  # Enables the given trackers in the given model
  #
  # I.e.:
  #
  #  The following would create two trackers (user and user_department), but only apply the former to Lead:
  #
  #  DataTracker.setup do
  #    tracker(:user) do
  #      update :updated_by, foreign_key: "updated_by_id", class_name: "::User"
  #      value { User.current }
  #    end
  #    tracker(:user_department) do
  #      update :updated_by_department, foreign_key: "updated_by_department_id", class_name: "::Department"
  #      value { User.current&.department }
  #    end
  #  end
  #
  #  DataTracker.apply(::Lead, user: true)
  #
  # @param model [ActiveRecord::Base] any activerecord model
  # @param options [Hash<Symbol,(Hash,Boolean)>] tracking options
  # @see {::DataTracker::ModelHelper}
  def self.apply(model, options)
    @trackers.each do |key, tracker|
      next unless options[key]

      tracker.apply(model, options[key] == true ? {} : options[key])
    end
  end
end
