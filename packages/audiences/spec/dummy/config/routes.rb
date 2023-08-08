# frozen_string_literal: true

Rails.application.routes.draw do
  resources :example_owners, only: %i[show]
end
