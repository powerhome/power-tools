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

    def destroy
      TwoPercent::DeleteEvent.create(resource: params[:resource_type], id: params[:id])

      head :ok
    end

  private

    def scim_params
      params.except(:controller, :action, :resource_type).as_json.with_indifferent_access
    end
  end
end
