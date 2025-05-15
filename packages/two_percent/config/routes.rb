# frozen_string_literal: true

TwoPercent::Engine.routes.draw do
  post "/Bulk" => "bulk#_dispatch"
  post "/:resource_type" => "scim#create"
  patch "/:resource_type/:id" => "scim#update"
  put "/:resource_type/:id" => "scim#replace"
  delete "/:resource_type/:id" => "scim#destroy"
end
