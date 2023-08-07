# frozen_string_literal: true

require "audiences/scim_proxy"

module Audiences
  class ScimProxyController < ApplicationController
    def get
      status, body = ScimProxy.get(params[:scim_path], scim_params)

      render body: body, status: status, content_type: "application/json"
    end

  private

    def scim_params
      params.except(:scim_path, :controller, :action).permit!.to_h
    end
  end
end
