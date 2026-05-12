# frozen_string_literal: true

module TwoPercent
  include ActiveSupport::Configurable

  # Configuration options

  #
  # Authentication configuration. This defaults to true, meaning that the SCIM
  # endpoints are open to the public.
  #
  # To authenticate requests, set this configuration to a lambda that will receive
  # the request and return true if the request is authenticated.
  #
  # Raising an exception will also prevent the execution of the request, but the
  # exception will not be caught and should be handled by the application middlewares.
  #
  # I.e.:
  #
  #   TwoPercent.configure do |config|
  #     config.authenticate = ->(*) { authenticate_request }
  #   end
  #
  # I.e:
  #
  #   TwoPercent.configure do |config|
  #     config.authenticate = ->(request) do
  #       request.env["warden"].authenticate!
  #     end
  #   end
  #
  config_accessor :authenticate do
    ->(*) do
      TwoPercent.logger.warn(<<~MESSAGE)
        TwoPercent authenticate is currently configured using a default and is blocking authenticaiton.

        To make this wraning go away provide a configuration for `TwoPercent.config.authenticate`.

        The value should:
          1. Be callable like a Proc.
          2. Return true when the request is permitted.
          3. Return false when the request is not permitted.
      MESSAGE

      false
    end
  end

  #
  # Configures a logger to be used by TwoPercent modules.
  # It can be accessed through `TwoPercent.logger`
  # `TwoPercent.logger` will default to Rails.logger
  #
  config_accessor :logger

  #
  # HTTP header name for correlation ID tracking
  # Defaults to "X-Correlation-Id" (common microservices pattern)
  # Set to your IdP's correlation header (e.g., "SCIM-Request-ID")
  #
  # I.e.:
  #
  #   TwoPercent.configure do |config|
  #     config.correlation_id_header = "SCIM-Request-ID"
  #   end
  #
  config_accessor :correlation_id_header, default: "X-Correlation-Id"

  class ConfigurationError < StandardError; end
end
