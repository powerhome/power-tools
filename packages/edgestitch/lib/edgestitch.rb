# frozen_string_literal: true

require "edgestitch/exporter"
require "edgestitch/renderer"
require "edgestitch/tasks"
require "edgestitch/version"

require "edgestitch/mysql/dump"

# Facade module to access public Edgestitch functions
#
module Edgestitch
  module_function

  # Define a db:stitch task
  # @see Edgestitch::Tasks
  def define_create(...)
    ::Edgestitch::Tasks.define_create(...)
  end

  # Define a db:stitch:<engine_name> task
  # @see Edgestitch::Tasks
  def define_self(...)
    ::Edgestitch::Tasks.define_self(...)
  end
end
