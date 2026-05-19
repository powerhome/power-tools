# frozen_string_literal: true

require "uri"

module Stagecoach
  module Config
    DEFAULT_QUERY_TIMEOUT = 60
    DEFAULT_PLAN_TIMEOUT = 10
    DEFAULT_SLOW_QUERY_THRESHOLD_SECONDS = 5

    REQUIRED_KEYS = %i[server user catalog schema].freeze
    URL_SERVER_PATTERN = %r{\Ahttps?://}i

  module_function

    def client_options(config)
      symbolized = symbolize(config)
      validate!(symbolized)
      server, scheme_ssl = normalize_server(symbolized[:server])
      {
        server: server,
        user: symbolized[:user],
        password: symbolized[:password],
        catalog: symbolized[:catalog],
        schema: symbolized[:schema],
        ssl: symbolized.fetch(:ssl, scheme_ssl),
        http_proxy: symbolized[:http_proxy],
        time_zone: symbolized[:time_zone],
        query_timeout: symbolized.fetch(:query_timeout, DEFAULT_QUERY_TIMEOUT),
        plan_timeout: symbolized.fetch(:plan_timeout, DEFAULT_PLAN_TIMEOUT),
      }.compact
    end

    # trino-client wants server as bare host:port and infers scheme from the
    # ssl: option. Accept URL-form servers (https://host:port) too, since that
    # is what most config sources (database.yml, NitroConfig) hand back, and
    # split them into host:port plus an ssl flag.
    def normalize_server(server)
      raw = server.to_s
      return [raw, nil] unless raw.match?(URL_SERVER_PATTERN)

      uri = URI.parse(raw)
      host_port = uri.port ? "#{uri.host}:#{uri.port}" : uri.host.to_s
      [host_port, uri.scheme.casecmp?("https")]
    end

    def slow_query_threshold(config)
      symbolized = symbolize(config)
      symbolized.fetch(:slow_query_threshold_seconds, DEFAULT_SLOW_QUERY_THRESHOLD_SECONDS).to_f
    end

    def validate!(config)
      symbolized = symbolize(config)
      missing = REQUIRED_KEYS.reject { |k| symbolized[k] && !symbolized[k].to_s.empty? }
      return if missing.empty?

      raise Stagecoach::ConfigurationError,
            "stagecoach: missing required config keys: #{missing.join(', ')}"
    end

    def symbolize(config)
      config.to_h.transform_keys(&:to_sym)
    end
  end
end
