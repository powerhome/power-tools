# frozen_string_literal: true

require "active_record"
require "rgeo/active_record"

require "active_record/mysql_rgeo/version"

module ActiveRecord
  # Adds RGeo-backed spatial support to Active Record's built-in MySQL
  # adapters (trilogy and mysql2).
  module MysqlRgeo
    extend ActiveSupport::Autoload

    autoload :ArelVisitor
    autoload :AttributeTypes
    autoload :Column
    autoload :ColumnMetadata
    autoload :ColumnMethods
    autoload :ConflictingGemError
    autoload :DeprecatedConstants
    autoload :GeometryParser
    autoload :Installer
    autoload :NativeDatabaseTypes
    autoload :Quoting
    autoload :SchemaCreation
    autoload :SchemaDumper
    autoload :SchemaStatements
    autoload :SpatialColumn
    autoload :SpatialColumnOptions
    autoload :SpatialDefault
    autoload :SpatialExpressions
    autoload :TableDefinition
    autoload :TypeMap

    module Type # :nodoc:
      extend ActiveSupport::Autoload

      autoload :Spatial
    end

    # Warns about this gem's deprecated APIs. Rails applications list it in
    # Rails.application.deprecators.
    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("1.0", "activerecord-mysql-rgeo")
    end
  end
end

ActiveSupport.on_load(:before_initialize) do
  deprecators[:activerecord_mysql_rgeo] = ActiveRecord::MysqlRgeo.deprecator
end
ActiveSupport.on_load(:active_record) do
  ActiveRecord::MysqlRgeo::ConflictingGemError.check!
  ActiveRecord::MysqlRgeo::DeprecatedConstants.define
end

ActiveSupport.on_load(:active_record_trilogyadapter) do
  ActiveRecord::MysqlRgeo::Installer.install(self, adapter: :trilogy)
end
ActiveSupport.on_load(:active_record_mysql2adapter) do
  ActiveRecord::MysqlRgeo::Installer.install(self, adapter: :mysql2)
end
