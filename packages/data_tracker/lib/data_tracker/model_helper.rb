# frozen_string_literal: true

module DataTracker
  module ModelHelper
    def track_data(...)
      ::DataTracker.apply(self, ...)
    end
  end
end
