# frozen_string_literal: true

module Wayfinding
  class Error < StandardError
  end

  # Raised when looking up a destination that was never registered.
  class UnregisteredDestination < Error
  end

  # Raised at registration when a destination is missing fields its kind requires,
  # or when its resolution strategy is ambiguous or incomplete.
  class InvalidDestination < Error
  end

  # Raised when a destination declares a kind that was never defined.
  class UnknownKind < Error
  end
end
