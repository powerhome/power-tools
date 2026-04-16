# frozen_string_literal: true

module TwoPercent
  module Domain
    module Events
      # Base class for domain events
      # These are domain-focused, not SCIM-specific
      class BaseEvent < AetherObservatory::EventBase
        event_prefix "two_percent.domain"
        
        attribute :correlation_id
      end
    end
  end
end
