# frozen_string_literal: true

require "edgestitch/exporter"
require "edgestitch/stitcher"
require "edgestitch/tasks"
require "edgestitch/version"

require "edgestitch/mysql/dump"

# Facade module to access public Edgestitch functions
#
module Edgestitch
module_function

  # Define a db:stitch task
  # @see Edgestitch::Tasks
  def define_stitch(...)
    ::Edgestitch::Tasks.define_stitch(...)
  end

  # Define a db:stitch:<engine_name> task
  # @see Edgestitch::Tasks
  def define_engine(...)
    ::Edgestitch::Tasks.define_engine(...)
  end
end
