# frozen_string_literal: true

module TwoPercent
  class ApplicationController < ActionController::API
    before_action :authenticate

    def authenticate
      instance_exec(&TwoPercent.config.authenticate)
    end
  end
end
