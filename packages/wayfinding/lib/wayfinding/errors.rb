# frozen_string_literal: true

module Wayfinding
  Error = Class.new(StandardError)

  # Raised when looking up a destination that was never registered.
  UnregisteredDestination = Class.new(Error)

  # Raised at registration when a destination is missing fields its kind requires,
  # or when its resolution strategy is ambiguous or incomplete.
  InvalidDestination = Class.new(Error)

  # Raised when a destination declares a kind that was never defined.
  UnknownKind = Class.new(Error)
end
