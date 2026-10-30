# frozen_string_literal: true

require "active_record"
require "rgeo/active_record"

require "active_record/mysql_rgeo/version"

module ActiveRecord
  # Adds RGeo-backed spatial support to Active Record's built-in MySQL
  # adapters (trilogy and mysql2).
  module MysqlRgeo
  end
end
