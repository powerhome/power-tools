# frozen_string_literal: true

module TwoPercent
  class ScimController < ApplicationController
    def create
      TwoPercent::CreateEvent.create(resource: params[:resource_type], params: scim_params)

      head :ok
    end

    def update
      TwoPercent::UpdateEvent.create(resource: params[:resource_type], id: params[:id], params: scim_params)

      head :ok
    end

    def replace
      TwoPercent::ReplaceEvent.create(resource: params[:resource_type], id: params[:id], params: scim_params)

      head :ok
    end

  private

    def scim_params
      params.without(:controller, :action, :resource_type, :id).as_json.deep_symbolize_keys
    end
  end
end
