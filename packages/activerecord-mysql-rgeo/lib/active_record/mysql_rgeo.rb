# frozen_string_literal: true

require "active_record"
require "rgeo/active_record"

require "active_record/mysql_rgeo/version"

module ActiveRecord
  # Adds RGeo-backed spatial support to Active Record's built-in MySQL
  # adapters (trilogy and mysql2).
  module MysqlRgeo
    extend ActiveSupport::Autoload

    autoload :ColumnMetadata
    autoload :GeometryParser
    autoload :Installer
    autoload :SchemaStatements
    autoload :SpatialColumn
    autoload :TypeMap

    module Type # :nodoc:
      extend ActiveSupport::Autoload

      autoload :Spatial
    end
  end
end

ActiveSupport.on_load(:active_record_trilogyadapter) { ActiveRecord::MysqlRgeo::Installer.install(self) }
ActiveSupport.on_load(:active_record_mysql2adapter) { ActiveRecord::MysqlRgeo::Installer.install(self) }
