# frozen_string_literal: true

module ScimShady
  class Error < StandardError; end

  class UnknownError < Error; end

  class AuthenticationError < Error; end

  class RequestError < Error; end

  class UnknownSchema < Error; end

  class ResourceNotFound < Error
    def initialize(body)
      super(body["detail"])
    end
  end
end
