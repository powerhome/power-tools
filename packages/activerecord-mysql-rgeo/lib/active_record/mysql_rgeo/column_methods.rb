# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Spatial column helpers for create_table and change_table:
    #
    #   create_table :places do |t|
    #     t.st_point :location, srid: 3857
    #     t.geography :area
    #   end
    #
    # Each takes the srid:, geographic:, has_z: and has_m: options besides
    # the usual column options.
    module ColumnMethods
      # Helper names, as activerecord-mysql2rgeo-adapter defines them.
      TYPES = %i[
        geometry geography
        point st_point polygon st_polygon
        line_string linestring
        multi_point multipoint multi_line_string multilinestring multi_polygon multipolygon
        geometry_collection geometrycollection
      ].freeze

      TYPES.each do |type|
        define_method(type) do |*names, **options|
          names.each { |name| column(name, type, **options) }
        end
      end

      # A spatial column of the given +type+:
      #
      #   t.spatial :location, type: :st_point, srid: 3857
      def spatial(*names, type: nil, **options)
        unless type
          raise ArgumentError, "t.spatial needs a type, for example: t.spatial :#{names.first}, type: :st_point"
        end

        names.each { |name| column(name, type, **options) }
      end
    end
  end
end
