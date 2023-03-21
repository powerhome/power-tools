# frozen_string_literal: true

Rails.application.routes.draw do
  mount CamelTrail::Engine => "/camel_trail"
end
