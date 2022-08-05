# frozen_string_literal: true

require "active_support/tagged_logging"

module Lumberaxe
  class LogChooser
    cattr_accessor :log_level

    def self.logger(progname:)
      logger = Logger.new(primary_logdev, progname: progname)
      logger.level = log_level
      logger.formatter = JSONFormatter.new if structured_logging?
      logger
    end

    # Standard practice for applications running in Docker containers
    # is to send their logging output to STDOUT instead of various
    # logfiles on disk.
    cattr_accessor :primary_logdev do
      $stdout
    end

    def self.structured_logging?
      ENV.key?("STRUCTURED_LOGGING")
    end
  end

  class JSONFormatter < ::Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter

    def call(severity, time, progname, data)
      data = { message: data.to_s } unless data.is_a?(Hash)

      formatter = {
        level: severity,
        time: time,
        progname: progname,
      }.merge(format_data(data))

      "#{formatter.to_json}\r\n}"
    end

  private

    def format_data(data)
      data.merge!(current_tags.each_with_object({}) do |tag, hash|
        if tag.include?("=")
          key, value = tag.split("=")
          hash[key] = value
        else
          hash[:tags] ||= []
          hash[:tags] << key
        end
        hash
      end)
    end
  end
end
