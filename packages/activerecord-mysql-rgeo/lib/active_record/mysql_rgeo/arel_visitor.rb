# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Writes spatial Arel nodes as MySQL SQL: RGeo geometries, bounding boxes,
    # and the arguments of rgeo-activerecord's spatial functions
    # (+st_distance+, +st_contains+ and the others), which may also be WKT or
    # EWKT. Prepended to Arel::Visitors::MySQL; Rails visits every other node.
    #
    # Like activerecord-mysql2rgeo-adapter 9.x, a String is only read as WKT
    # in a spatial function argument. Anywhere else Arel rejects it.
    module ArelVisitor # :nodoc:
      include RGeo::ActiveRecord::SpatialToSql

      # Function names rgeo-activerecord's SpatialToSql expects databases to map.
      FUNCTIONS = {
        "st_wkttosql" => "ST_GeomFromText",
        "st_wkbtosql" => "ST_GeomFromWKB",
        "st_length" => "ST_Length",
      }.freeze

      def st_func(standard_name)
        FUNCTIONS.fetch(standard_name.downcase, standard_name)
      end

      def visit_in_spatial_context(node, collector)
        return visit(node, collector) unless node.is_a?(String)

        wkt, srid = GeometryParser.split_srid(node)
        collector << Quoting.geometry_from_text(quote(wkt), srid)
      end

    private

      def visit_RGeo_Feature_Instance(node, collector)
        collector << quote(node)
      end

      def visit_RGeo_Cartesian_BoundingBox(node, collector)
        collector << quote(node.to_geometry)
      end
    end
  end
end
