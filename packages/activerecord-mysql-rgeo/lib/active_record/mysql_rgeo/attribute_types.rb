# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Spatial types for the attribute API:
    #
    #   attribute :location, :st_point, srid: 3857
    #
    # Registered for each MySQL adapter only, so they don't clash with other
    # spatial adapters in the same application.
    module AttributeTypes # :nodoc:
      # Each type name and the geometric type it stands for.
      TYPES = {
        st_point: "point",
        st_polygon: "polygon",
        line_string: "linestring",
        multi_line_string: "multilinestring",
        multi_point: "multipoint",
        multi_polygon: "multipolygon",
      }.freeze

      def self.register(adapter)
        TYPES.each do |name, geo_type|
          ActiveRecord::Type.register(name, adapter: adapter) do |_name, **options|
            Type::Spatial.new(geo_type, geo_type: geo_type, **options)
          end
        end
      end
    end
  end
end
