# frozen_string_literal: true

module TwoPercent
  class ScimController < ApplicationController
    def create
      TwoPercent::CreateEvent.create(resource: params[:resource_type], params: scim_params)

      head :ok
    end

  private

    def scim_params
      params.without(:controller, :action, :resource_type).as_json.deep_symbolize_keys
    end
  end
end
