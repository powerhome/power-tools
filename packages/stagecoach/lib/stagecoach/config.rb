# frozen_string_literal: true

module Stagecoach
  module Config
    DEFAULT_QUERY_TIMEOUT = 150
    DEFAULT_PLAN_TIMEOUT = 30
    DEFAULT_SLOW_QUERY_THRESHOLD_SECONDS = 20
    DEFAULT_HTTP_PORT = 8080
    DEFAULT_HTTPS_PORT = 443

    REQUIRED_KEYS = %i[host user catalog schema].freeze

  module_function

    def client_options(config)
      symbolized = symbolize(config)
      validate!(symbolized)
      ssl = symbolized.fetch(:ssl, false)
      port = symbolized.fetch(:port, default_port(ssl))
      {
        server: "#{symbolized[:host]}:#{port}",
        user: symbolized[:user],
        password: symbolized[:password],
        catalog: symbolized[:catalog],
        schema: symbolized[:schema],
        ssl: ssl,
        http_proxy: symbolized[:http_proxy],
        time_zone: symbolized[:time_zone],
        query_timeout: symbolized.fetch(:query_timeout, DEFAULT_QUERY_TIMEOUT),
        plan_timeout: symbolized.fetch(:plan_timeout, DEFAULT_PLAN_TIMEOUT),
      }.compact
    end

    def default_port(ssl)
      ssl ? DEFAULT_HTTPS_PORT : DEFAULT_HTTP_PORT
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
