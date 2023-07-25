# frozen_string_literal: true

Rails.application.routes.draw do
  mount Audiences::Engine => "/audiences"
end
