# frozen_string_literal: true

require "digest/md5"

module ScimShady
  class MockClient < Client
    def initialize(fixtures_path, mocks = [])
      @fixtures_path = fixtures_path
      @initial_mocks = mocks

      reset_mocks!
    end

    def mock(method:, path:, fixture: nil, query: {}, body: {}, response: {})
      mocks.store key_for(method, path, query, body), fixture ? @fixtures_path.join(fixture) : response
    end

    def reset_mocks!
      @mocks = {}
      @initial_mocks.each { mock(**_1) }
    end

    def perform_request(method:, path:, query: {}, body: {}, **kwargs)
      mock_key = key_for(method, path, query, body)
      response = mocks.fetch(mock_key) do
        raise "Invalid request: #{method} #{path} (#{query.inspect}) (#{body.to_json})"
      end
      handle_success response.try(:read) || response.to_json, **kwargs
    end

    private

    attr_reader :mocks

    def key_for(method, path, query, body)
      [method, path, query, body.to_json].compact
    end
  end
end
