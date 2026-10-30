# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    module Type
      # The Active Record type of spatial columns. It turns the values MySQL
      # returns, and WKT, EWKT, WKB or EWKB strings, into RGeo geometries built
      # by the factory RGeo::ActiveRecord::SpatialFactoryStore picks for the
      # column.
      #
      # +sql_type+ comes from the column definition, for example "point",
      # "geometry(Point,3857)" or "geography(Polygon,4326)".
      class Spatial < ActiveModel::Type::Value
        GEOMETRIC_TYPE = /([a-z]+[^zm])(z?)(m?)/i

        # Splits a spatial SQL type into
        # <tt>[geo_type, srid, has_z, has_m, geographic]</tt>.
        #
        #   parse_sql_type("geometry(PointZ,3857)") # => ["Point", 3857, true, false, false]
        #   parse_sql_type("geography")             # => ["geography", 0, false, false, true]
        def self.parse_sql_type(sql_type)
          case sql_type
          when /(geography|geometry)\((.*)\)$/i
            parse_type_parameters(Regexp.last_match(2).split(","), Regexp.last_match(1).casecmp?("geography"))
          when /\A(geography|geometry)\z/i
            [Regexp.last_match(1), 0, false, false, Regexp.last_match(1).casecmp?("geography")]
          else
            [sql_type, 0, false, false, false]
          end
        end

        # The geometric type name RGeo::ActiveRecord::SpatialFactoryStore
        # expects: "point", "line_string", "multi_polygon", ...
        def self.normalize_geo_type(geo_type)
          case geo_type.to_s.underscore.delete("_")
          when "geometrycollection" then "geometry_collection"
          when "linestring" then "line_string"
          when "multilinestring" then "multi_line_string"
          when "multipoint" then "multi_point"
          when "multipolygon" then "multi_polygon"
          else geo_type.to_s.underscore.presence
          end
        end

        # "PointZ", "4326" => ["Point", 4326, true, false, geographic]
        def self.parse_type_parameters(parameters, geographic)
          srid = parameters.last.to_s[/\d+/].to_i
          match = GEOMETRIC_TYPE.match(parameters.first.to_s)
          return [nil, srid, false, false, geographic] unless match

          [match[1], srid, match[2].casecmp?("z"), match[3].casecmp?("m"), geographic]
        end
        private_class_method :parse_type_parameters

        def initialize(sql_type = "geometry", geo_type: nil, srid: nil, geographic: false,
                       has_z: false, has_m: false, **)
          super()
          @sql_type = -(geographic ? "geography" : sql_type.to_s)
          parsed_type, parsed_srid, parsed_z, parsed_m, parsed_geographic = self.class.parse_sql_type(@sql_type)
          @geo_type = -self.class.normalize_geo_type(geo_type || parsed_type).to_s
          @srid = srid || parsed_srid
          @has_z = has_z || parsed_z
          @has_m = has_m || parsed_m
          @geographic = geographic || parsed_geographic
          freeze
        end

        def type
          :geometry
        end

        def spatial?
          true
        end

        def klass
          RGeo::Feature::Geometry
        end

        # Returns the RGeo geometry to write. Columns with SRID 0 take
        # geometries of any SRID, cast to the column's factory.
        def serialize(value)
          return if value.nil?

          geometry = cast_value(value)
          return cast_to_column_srid(geometry) if RGeo::Feature::Geometry.check_type(geometry)

          raise ArgumentError, "#{value.inspect} is not a geometry. Assign an RGeo geometry, or WKT, " \
                               "EWKT, WKB or EWKB that describes one."
        end

      private

        def cast_to_column_srid(geometry)
          return geometry if @geographic || !@srid.to_i.zero? || geometry.srid == @srid

          RGeo::Feature.cast(geometry, factory: spatial_factory, project: true)
        end

        def cast_value(value)
          return value unless value.is_a?(::String)

          GeometryParser.new(@srid) { |srid| spatial_factory(srid) }.parse(value)
        end

        # Not memoized: the type is frozen, and SpatialFactoryStore already
        # caches the factories it builds.
        def spatial_factory(srid = @srid)
          RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(
            geo_type: @geo_type,
            has_m: @has_m,
            has_z: @has_z,
            sql_type: @geographic ? "geography" : "geometry",
            srid: srid
          )
        end
      end
    end
  end
end
