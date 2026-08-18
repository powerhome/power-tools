# frozen_string_literal: true

module Wayfinding
  # The result of Wayfinding.of_kind. An Array of Destination with ability filtering.
  class DestinationList < Array
    # Destinations the given ability permits. Destinations without an action are
    # excluded: there is nothing to authorize against.
    def accessible_by(ability)
      self.class.new(select do |destination|
        destination.action && ability.can?(destination.action, destination.subject)
      end)
    end
  end
end
