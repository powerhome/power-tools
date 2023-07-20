# frozen_string_literal: true

module Audiences
  # Audiences Engine
  #
  # i.e.: `mount Audiences::Engine`
  #
  class Engine < ::Rails::Engine
    isolate_namespace Audiences
  end
end
