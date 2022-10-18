# frozen_string_literal: true

require "active_support/tagged_logging"

module Lumberaxe
  class JSONFormatter < ::Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter

    def call(severity, time, progname, data)
      data = data.is_a?(Hash) ? format_data(data) : { message: data.to_s }

      {
        level: severity,
        time: time,
        progname: progname,
      }.merge(data).to_json.concat("\r\n")
    end

    def format_data(data)
      data.merge!(current_tags.each_with_object({}) do |tag, hash|
                    if tag.include?("=")
                      key, value = tag.split("=")
                      hash[key] = value
                    else
                      hash[:tags] ||= []
                      hash[:tags] << tag
                    end
                    hash
                  end)
    end
  end
end
