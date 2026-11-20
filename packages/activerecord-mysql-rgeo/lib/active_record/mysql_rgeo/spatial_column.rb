# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # A spatial column. Its sql_type, such as "geometry(Point,3857)" or
    # "geography(PointZ,4326)", carries the geometric type, the SRID and the
    # details read from the column comment. Everything else is read from it,
    # so the schema cache keeps them without extra state.
    class SpatialColumn < ConnectionAdapters::MySQL::Column
      # Active Record 8.1 added cast_type as Column#initialize's second argument.
      COLUMN_TAKES_CAST_TYPE = ActiveRecord.gem_version >= Gem::Version.new("8.1.0.alpha")

      # Type names migrations use for a column's geometric type.
      LIMIT_TYPES = { "point" => "st_point", "polygon" => "st_polygon" }.freeze

      # The sql_type of a column MySQL reports as +mysql_type+ ("point",
      # "geomcollection", ...).
      def self.sql_type_for(mysql_type, srid:, geographic: false, has_z: false, has_m: false)
        geo_type = (mysql_type.casecmp?("geomcollection") ? "geometrycollection" : mysql_type).camelize
        geo_type += "Z" if has_z
        geo_type += "M" if has_m
        "#{geographic ? 'geography' : 'geometry'}(#{geo_type},#{srid})"
      end

      # A copy of +column+ with spatial type metadata.
      def self.from(column, sql_type_metadata:, cast_type:, comment:, default:)
        arguments = [column.name, default, sql_type_metadata, column.null, column.default_function]
        arguments.insert(1, cast_type) if COLUMN_TAKES_CAST_TYPE
        new(*arguments, collation: column.collation, comment: comment)
      end

      def spatial?
        true
      end

      def geometric_type
        RGeo::ActiveRecord.geometric_type_from_name(geo_type) || RGeo::Feature::Geometry
      end

      def srid
        parsed_sql_type[1]
      end

      def has_z
        parsed_sql_type[2]
      end
      alias has_z? has_z

      def has_m
        parsed_sql_type[3]
      end
      alias has_m? has_m

      def geographic
        parsed_sql_type[4]
      end
      alias geographic? geographic

      def multi?
        Type::Spatial.normalize_geo_type(geo_type).start_with?("multi_", "geometry_collection")
      end

      # The options a migration needs to recreate the column, as
      # activerecord-mysql2rgeo-adapter reports them.
      def limit
        limit = { type: limit_type, srid: srid }
        limit[:geographic] = true if geographic?
        limit[:has_z] = true if has_z?
        limit[:has_m] = true if has_m?
        limit
      end

    private

      def parsed_sql_type
        Type::Spatial.parse_sql_type(sql_type)
      end

      def geo_type
        parsed_sql_type[0]
      end

      def limit_type
        name = Type::Spatial.normalize_geo_type(geo_type)
        LIMIT_TYPES.fetch(name, name)
      end
    end
  end
end
