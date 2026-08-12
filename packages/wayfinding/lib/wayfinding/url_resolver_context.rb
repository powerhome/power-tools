# frozen_string_literal: true

module Wayfinding
  # Evaluates a destination block as a URL by delegating route helper calls to
  # the registered engine and replacing a trailing `_path` with `_url`.
  class UrlResolverContext
    def initialize(url_helpers)
      @url_helpers = url_helpers
    end

  private

    def method_missing(name, ...)
      @url_helpers.public_send(url_helper_name(name), ...)
    end

    def respond_to_missing?(name, include_private = false)
      @url_helpers.respond_to?(url_helper_name(name), include_private)
    end

    def url_helper_name(name)
      name.to_s.sub(/_path\z/, "_url")
    end
  end
end
