# frozen_string_literal: true

Audiences::Engine.routes.draw do
  get "/scim(/*scim_path)" => "scim_proxy#get", as: :scim_proxy
  get "/:key" => "contexts#show", as: :signed_context
end

Rails.application.routes.draw do
  mount Audiences::Engine, at: "/audiences", as: :audiences

  direct :audience_context do |owner, options|
    audiences.route_for(:signed_context, key: Audiences.sign(owner), **options)
  end

  direct :audience_scim_proxy do |options|
    audiences.route_for(:scim_proxy, **options)
  end
end
