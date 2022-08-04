# frozen_string_literal: true

module Lumberaxe
  class Railtie < Rails::Railtie
    initializer "lumberaxe.configurations" do
      Lumberaxe::LogChooser.log_level = Rails.application.config.log_level
    end
  end
end
