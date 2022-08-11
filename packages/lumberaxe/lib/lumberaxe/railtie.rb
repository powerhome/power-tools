# frozen_string_literal: true

require "lograge"

module Lumberaxe
  class Railtie < Rails::Railtie
    initializer "lumberaxe.configurations", before: :initialize_logger do |app|
      Rails.logger = app.config.logger || Lumberaxe::Logger.new(progname: "app", level: app.config.log_level)
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
