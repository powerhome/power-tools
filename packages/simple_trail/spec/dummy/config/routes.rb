# frozen_string_literal: true

Rails.application.routes.draw do
  mount NitroHistory::Engine => "/nitro_history"
end
