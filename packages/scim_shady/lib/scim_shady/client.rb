# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module ScimShady
  class Client
    attr_reader :uri, :headers, :logger

    def initialize(uri:, headers: {}, logger: nil)
      @uri = URI.parse(uri)
      @headers = headers.freeze
      @logger = logger
    end

    def get(**kwargs)
      perform_request(method: :Get, **kwargs)
    end

    def post(**kwargs)
      perform_request(method: :Post, **kwargs)
    end

    def put(**kwargs)
      perform_request(method: :Put, **kwargs)
    end

    def patch(**kwargs)
      perform_request(method: :Patch, **kwargs)
    end

    def perform_request(method:, path:, query: {}, list: nil, model: nil, body: nil)
      request_uri = URI.join(uri, path.to_s)
      request_uri.query = URI.encode_www_form(query)
      logger&.info "Requesting #{request_uri.inspect}"
      request = ::Net::HTTP.const_get(method).new(request_uri, headers)
      request.body = body.to_json if body
      response = http.request(request)

      handle_response response, list: list, model: model
    end

    private

    def http
      @http ||= ::Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == "https"
      end
    end

    def handle_response(response, **kwargs)
      case response
      when Net::HTTPSuccess then handle_success(response.body, **kwargs)
      when Net::HTTPNotFound then raise ScimShady::ResourceNotFound, response.body
      when Net::HTTPUnauthorized then raise ScimShady::AuthenticationError, response.body
      when Net::HTTPClientError then raise ScimShady::RequestError, response.body
      when Net::HTTPServerError then raise ScimShady::ServerError, response.body
      else
        raise ScimShady::UnknownError, response.body.inspect
      end
    end

    def handle_success(body, list: false, model: false)
      parsed_body = JSON.parse(body)

      if list
        ScimShady::ListResponse.new(parsed_body, list)
      elsif model
        model.new(parsed_body)
      else
        parsed_body
      end
    end
  end
end
