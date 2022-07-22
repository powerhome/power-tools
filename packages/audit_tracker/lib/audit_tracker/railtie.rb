# frozen_string_literal: true

module AuditTracker
  # Auto injects the ::AuditTracker::ModelHelper into ActiveRecord classes
  #
  class Railtie < Rails::Railtie
    railtie_name :audit_tracker

    initializer "audit_tracker.initialize_model_helper" do
      ActiveSupport.on_load(:active_record) do
        extend ::AuditTracker::ModelHelper
      end
    end
  end
end
