# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Active Record 8.2 can dump the schema cache as JSON, for the classes
    # registered with its serializer. This registers the spatial column and
    # type. The serializer is private API:
    # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/schema_cache_serializer.rb
    module JsonSchemaCache # :nodoc:
      SUPPORTED = ActiveRecord.gem_version >= Gem::Version.new("8.2.0.alpha")

      def self.register
        return unless SUPPORTED

        ConnectionAdapters::JSONSchemaCacheSerializer.register("mysql_rgeo_spatial_column", SpatialColumn)
        ConnectionAdapters::JSONSchemaCacheSerializer.register("mysql_rgeo_spatial", Type::Spatial)
      end
    end
  end
end
