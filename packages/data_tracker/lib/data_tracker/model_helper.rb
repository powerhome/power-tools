# frozen_string_literal: true

module DataTracker
  # Model helper for setting up trackers in an ActiveRecord model
  #
  module ModelHelper
    # TODO: write documentation
    def track_data(...)
      ::DataTracker.apply(self, ...)
    end
  end
end
