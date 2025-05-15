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
      false
    end
  end
end
