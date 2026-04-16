# frozen_string_literal: true

module TwoPercent
  module Domain
    # Domain events (provider-agnostic)
    module Events
      autoload :BaseEvent, "two_percent/domain/events/base_event"
      autoload :UserCreated, "two_percent/domain/events/user_events"
      autoload :UserUpdated, "two_percent/domain/events/user_events"
      autoload :UserDeleted, "two_percent/domain/events/user_events"
      autoload :GroupCreated, "two_percent/domain/events/group_events"
      autoload :GroupUpdated, "two_percent/domain/events/group_events"
      autoload :GroupDeleted, "two_percent/domain/events/group_events"
    end
  end
end
