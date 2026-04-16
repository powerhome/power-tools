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
  # Repository configuration for domain models
  # Apps must provide their own User and Group repository classes
  #
  # I.e.:
  #
  #   TwoPercent.configure do |config|
  #     config.user_repository_class = ScimUser
  #     config.group_repository_class = ScimGroup
  #   end
  #
  config_accessor :user_repository_class
  config_accessor :group_repository_class

  #
  # Attribute mapping configuration
  # Maps SCIM attributes to model attributes
  #
  # For each SCIM attribute, specify either:
  # - A symbol for the model attribute name
  # - A proc/lambda for custom extraction
  #
  # I.e.:
  #
  #   TwoPercent.configure do |config|
  #     config.user_attribute_mapping = {
  #       scim_id: :id,
  #       external_id: :auth_service_id,
  #       user_name: :username,
  #       display_name: -> (user) { user.full_name },
  #       photos: -> (user) { [{ value: user.avatar_url }] }
  #     }
  #   end
  #
  config_accessor :user_attribute_mapping do
    {
      scim_id: :scim_id,
      external_id: :external_id,
      user_name: :user_name,
      display_name: :display_name,
      email: :email,
      active: :active
    }
  end

  config_accessor :group_attribute_mapping do
    {
      scim_id: :scim_id,
      external_id: :external_id,
      display_name: :display_name,
      resource_type: :resource_type,
      active: :active
    }
  end

  #
  # Column name where unmapped SCIM data is stored as JSON
  # Set to nil if you want to manually handle SCIM representation
  #
  config_accessor :scim_data_column do
    :scim_data
  end

  # Helper methods to access repositories
  def self.user_repository
    config.user_repository_class || raise(
      ConfigurationError,
      "TwoPercent.config.user_repository_class must be set. " \
      "See: https://github.com/powerhome/two_percent#configuration"
    )
  end

  def self.group_repository
    config.group_repository_class || raise(
      ConfigurationError,
      "TwoPercent.config.group_repository_class must be set. " \
      "See: https://github.com/powerhome/two_percent#configuration"
    )
  end

  class ConfigurationError < StandardError; end
end
