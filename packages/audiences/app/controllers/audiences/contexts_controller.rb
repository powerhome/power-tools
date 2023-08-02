# frozen_string_literal: true

module Audiences
  class ContextsController < ApplicationController
    def show
      render json: current_context.as_json(only: %w[match_all], methods: %w[key])
    end

  private

    def current_context
      @current_context ||= Audiences.load(params[:key])
    end
  end
end
