# frozen_string_literal: true

require_relative "audit_tracker/dsl"
require_relative "audit_tracker/model_helper"
require_relative "audit_tracker/railtie" if defined?(Rails)
require_relative "audit_tracker/tracker"
require_relative "audit_tracker/version"

# AuditTracker helps you centralize data tracking configuration to be used accross
# different models
module AuditTracker
  # Trackers setup in AuditTracker
  #
  # @return [Hash<Symbol,::AuditTracker::Tracker>]
  #
  def self.trackers
    @trackers ||= {}
  end

  # Setup `AuditTracker::Tracker`'s
  #
  # setup entry point for data trackers. Multiple calls to this method are cumulative,
  # and trackers with the same key override each other depending on load order.
  #
  # I.e.:
  #
  #   AuditTracker.setup do
  #     tracker :user do
  #       value { ::Internal::Current.user }
  #       create :created_by, foreign_key: :created_by_id, class_name: "::Internal::User"
  #       update :updated_by, foreign_key: :updated_by_id, class_name: "::Internal::User"
  #     end
  #     tracker :user_department do
  #       value { ::Internal::Current.user&.department }
  #       create(
  #         :created_by_department,
  #         foreign_key: :created_by_department_id,
  #         class_name: "::Internal::Department"
  #       )
  #       update(
  #         :updated_by_department,
  #         foreign_key: :updated_by_department_id,
  #         class_name: "::Internal::Department"
  #       )
  #     end
  #   end
  #
  # Trackers will track a specific value, so the `value`` is always required to be defined.
  # Each line after that define a different event. `create` and `update` are helper methods
  # to create events.
  #
  # `update` is tied to the `:save` event of activerecord. That means that the value will be
  # tracked before create and before update.
  #
  # Each event defined will generate an active record relation, and will update that relation
  # before the event (i.e.: `before_update`, `before_create`).
  #
  def self.setup(&block)
    ::AuditTracker::DSL.build(&block)
  end

  # Enables the given trackers in the given model
  #
  # I.e.:
  #
  #  The following would create two trackers (user and user_department), but only apply the
  #  former to Lead:
  #
  #  AuditTracker.setup do
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
  #  AuditTracker.apply(::Lead, user: true)
  #
  # @param model [ActiveRecord::Base] any activerecord model
  # @param options [Hash<Symbol,(Hash,Boolean)>] tracking options
  # @see ::AuditTracker::ModelHelper
  def self.apply(model, options)
    @trackers.each do |key, tracker|
      next unless options[key]

      tracker.apply(model, options[key] == true ? {} : options[key])
    end
  end
end
