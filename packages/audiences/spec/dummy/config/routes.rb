# frozen_string_literal: true

Rails.application.routes.draw do
  resources :example_owners
  root to: "example_owners#index"
end
