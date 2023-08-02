# frozen_string_literal: true

Audiences::Engine.routes.draw do
  get "/:key" => "contexts#show", as: :context
end
