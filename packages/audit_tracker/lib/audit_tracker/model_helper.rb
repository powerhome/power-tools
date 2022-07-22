# frozen_string_literal: true

module AuditTracker
  # Model helper for setting up trackers in an ActiveRecord model
  #
  module ModelHelper
    #
    # Helper to apply AuditTracker to a model. This helper is automatically added
    # to ActiveRecord::Base when it loads (@see {AuditTracker::Railtie})
    #
    # `track_data` options are the keys of the trackers defined. Each tracker is
    # enabled by passing `true` to it's key.
    #
    # I.e.:
    #
    #   track_data user: true, user_department: true
    #
    # A hash of options can also be used to override any tracker option:
    #
    #   track_data(
    #     user: {
    #       created_by: { class_name: "::ManagerUser" },
    #       updated_by: { class_name: "::ManagerUser" },
    #     }
    #   )
    #
    # And the value block can also be overriden:
    #
    #   track_data(
    #     user: {
    #       created_by: { class_name: "::ManagerUser", value: -> { User.current.becomes(ManagerUser) } },
    #       updated_by: { class_name: "::ManagerUser", value: -> { User.current.becomes(ManagerUser) } },
    #     }
    #   )
    #
    # @param options [Hash<Symbol,(Hash, Boolean)>] options hash
    def track_data(**options)
      ::AuditTracker.apply(self, **options)
    end
  end
end
