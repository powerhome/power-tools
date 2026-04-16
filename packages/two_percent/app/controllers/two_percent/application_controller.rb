# frozen_string_literal: true

module TwoPercent
  class ApplicationController < ActionController::API
    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ArgumentError, with: :handle_bad_request

    def authenticate
      instance_exec(&TwoPercent.config.authenticate)
    end

    private

    def handle_record_not_found(exception)
      # RFC 7644 Section 3.12: Error Response
      render json: {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
        detail: exception.message,
        status: "404"
      }, status: :not_found
    end

    def handle_validation_error(exception)
      # RFC 7644: 400 Bad Request for invalid data
      render json: {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
        detail: "Request contains invalid data",
        status: "400"
      }, status: :bad_request
    end

    def handle_bad_request(exception)
      # RFC 7644: 400 Bad Request for malformed requests
      render json: {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
        detail: "Request is malformed or contains invalid syntax",
        status: "400"
      }, status: :bad_request
    end
  end
end
