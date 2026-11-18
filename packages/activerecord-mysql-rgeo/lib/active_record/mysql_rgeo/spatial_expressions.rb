# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # MySQL spatial functions added to rgeo-activerecord's spatial
    # expressions, so they chain from table attributes, Arel.spatial
    # constants and other spatial functions:
    #
    #   places = Place.arel_table
    #   Place.where(places[:coordinates].st_distance_sphere(point).lt(500))
    module SpatialExpressions
      # The distance in meters between two points on a sphere, by default
      # the Earth. Pass +radius+ for another sphere; the distance is then in
      # its unit.
      def st_distance_sphere(rhs, radius = nil)
        arguments = [self, rhs]
        arguments << Arel::Nodes.build_quoted(radius) if radius
        RGeo::ActiveRecord::SpatialNamedFunction.new("ST_Distance_Sphere", arguments, [false, true, true, false])
      end
    end
  end
end
