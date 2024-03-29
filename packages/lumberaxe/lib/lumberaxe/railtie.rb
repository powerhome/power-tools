# frozen_string_literal: true

require "lograge"
require "lumberaxe"

module Lumberaxe
  class Railtie < Rails::Railtie
    initializer "lumberaxe.configurations", before: :initialize_logger do |app|
      Rails.logger = app.config.logger || Lumberaxe::Logger.new(progname: "app", level: app.config.log_level)

      app.config.log_tags = [
        ->(req) { "request_id=#{req.uuid}" },
        ->(req) { "IP=#{req.remote_ip}" },
      ]

      Lumberaxe::Logger.log_level = app.config.log_level
    end

    initializer "lumberaxe.lograge" do
      config.lograge.enabled = true
      config.lograge.formatter = Lograge::Formatters::Raw.new
      config.lograge.custom_options = ->(event) do
        { "params" => event.payload[:params].without("controller", "action") }
      end
    end
  end
end
