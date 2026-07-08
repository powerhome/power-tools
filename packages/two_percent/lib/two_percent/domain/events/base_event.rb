# frozen_string_literal: true

module TwoPercent
  module Domain
    module Events
      # Base class for domain events
      # These are domain-focused, not SCIM-specific
      class BaseEvent < AetherObservatory::EventBase
        event_prefix "two_percent.domain"

        attribute :correlation_id

        # Apply this event to a domain model class
        #
        # Events know how to apply themselves to domain models, implementing
        # the "tell, don't ask" principle and avoiding case statements.
        #
        # @param model_class [Class] The domain model class including Syncable
        # @return [ActiveRecord::Base, nil] The affected record, if any
        # @abstract Override in subclasses to implement event-specific logic
        def apply_to_model(model_class)
          raise NotImplementedError, "#{self.class} must implement #apply_to_model"
        end
      end
    end
  end
end
