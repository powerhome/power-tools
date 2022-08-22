# frozen_string_literal: true

require "logger"
require "active_support"
require "lumberaxe/logger"
require "lumberaxe/json_formatter"

module Lumberaxe
  def self.puma_formatter(level: "INFO", progname: "puma")
    ->(message) do
      {
        level: level,
        time: Time.now,
        progname: progname,
        message: message,
      }.to_json.concat("\r\n")
    end
  end
end
