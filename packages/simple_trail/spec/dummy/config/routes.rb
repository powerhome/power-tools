# frozen_string_literal: true

Rails.application.routes.draw do
  mount SimpleTrail::Engine => "/simple_trail"
end
