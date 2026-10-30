# frozen_string_literal: true

require "active_record"
require "rgeo/active_record"

require "active_record/mysql_rgeo/version"

module ActiveRecord
  # Adds RGeo-backed spatial support to Active Record's built-in MySQL
  # adapters (trilogy and mysql2).
  module MysqlRgeo
    extend ActiveSupport::Autoload

    autoload :AttributeTypes
    autoload :ColumnMetadata
    autoload :ColumnMethods
    autoload :GeometryParser
    autoload :Installer
    autoload :Quoting
    autoload :SchemaCreation
    autoload :SchemaStatements
    autoload :SpatialColumn
    autoload :SpatialColumnOptions
    autoload :SpatialDefault
    autoload :TableDefinition
    autoload :TypeMap

    module Type # :nodoc:
      extend ActiveSupport::Autoload

      autoload :Spatial
    end
  end
end

ActiveSupport.on_load(:active_record_trilogyadapter) do
  ActiveRecord::MysqlRgeo::Installer.install(self, adapter: :trilogy)
end
ActiveSupport.on_load(:active_record_mysql2adapter) do
  ActiveRecord::MysqlRgeo::Installer.install(self, adapter: :mysql2)
end
