# frozen_string_literal: true

require "edgestitch"

module Edgestitch
  class Railtie < ::Rails::Railtie
    rake_tasks { ::Edgestitch::Tasks.define_create }
  end
end
