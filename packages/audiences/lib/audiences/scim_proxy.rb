# frozen_string_literal: true

require "net/http"
require "uri"

module Audiences
  module ScimProxy
    mattr_accessor :config do
      {}
    end

  module_function

    def get(path, query)
      response = perform_request(path: path, method: :Get, query: query)

      [response.code, response.body]
    end

    private_class_method def perform_request(method:, path:, query: {})
      uri = URI.join(config[:uri], path)
      uri.query = URI.encode_www_form(query)
      request = ::Net::HTTP.const_get(method).new(uri, config[:headers])

      http = ::Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      http.request(request)
    end
  end
end
