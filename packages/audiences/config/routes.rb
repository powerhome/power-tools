# frozen_string_literal: true

Audiences::Engine.routes.draw do
  get "/scim(/*scim_path)" => "scim_proxy#get", as: :scim_proxy
  get "/:key" => "contexts#show", as: :context
end
