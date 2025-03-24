# frozen_string_literal: true

TwoPercent::Engine.routes.draw do
  post "/:resource_type" => "scim#create"
end
