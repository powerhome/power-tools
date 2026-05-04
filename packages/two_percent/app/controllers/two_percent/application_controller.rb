# frozen_string_literal: true

module TwoPercent
  class ApplicationController < ActionController::API
    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ArgumentError, with: :handle_bad_request

    def authenticate
      result = instance_exec(&TwoPercent.config.authenticate)

      return if result

      render_scim_error(
        status: :unauthorized,
        scim_type: nil, # RFC 7644: No scimType for 401
        detail: "Authentication failed"
      )
    end

  private

    def handle_record_not_found(exception)
      # RFC 7644: Error Response with scimType
      render_scim_error(
        status: :not_found,
        scim_type: "noTarget",
        detail: exception.message
      )
    end

    def handle_validation_error(exception)
      # RFC 7644: 400 Bad Request for invalid data
      scim_type = exception.message.match?(/uniqueness|unique/i) ? "uniqueness" : "invalidValue"

      render_scim_error(
        status: :bad_request,
        scim_type: scim_type,
        detail: exception.message
      )
    end

    def handle_bad_request(exception)
      # RFC 7644: 400 Bad Request for malformed requests
      scim_type = exception.message.match?(/schemas/i) ? "invalidValue" : "invalidSyntax"

      render_scim_error(
        status: :bad_request,
        scim_type: scim_type,
        detail: exception.message
      )
    end

    # RFC 7644 Section 3.12: SCIM Error Response Format
    #
    # scimType values:
    # - invalidFilter: The specified filter syntax was invalid
    # - tooMany: The specified filter yields many more results than the server is willing to calculate
    # - uniqueness: One or more of the attribute values are already in use or are reserved
    # - mutability: The attempted modification is not compatible with the target attribute's mutability
    # - invalidSyntax: The request body message structure was invalid or did not conform to the request schema
    # - invalidPath: The "path" attribute was invalid or malformed
    # - noTarget: The specified "path" did not yield an attribute or attribute value that could be operated on (404)
    # - invalidValue: A required value was missing, or the value specified was not compatible with the operation
    # - invalidVers: The specified SCIM protocol version is not supported
    # - sensitive: The specified request cannot be completed due to the passing of sensitive information
    #
    def render_scim_error(status:, scim_type:, detail:)
      error_response = {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status].to_s,
        detail: detail,
      }

      # RFC 7644: scimType is optional, only include if provided
      error_response[:scimType] = scim_type if scim_type

      render json: error_response, status: status
    end
  end
end
