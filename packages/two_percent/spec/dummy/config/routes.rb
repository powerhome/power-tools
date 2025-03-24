# frozen_string_literal: true

Rails.application.routes.draw do
  mount TwoPercent::Engine => "/scim"
end
