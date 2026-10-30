# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Writes RGeo geometries as SQL. Prepended to AbstractMysqlAdapter; any
    # other value is quoted by Rails.
    module Quoting # :nodoc:
      # MySQL reads SRID 4326 coordinates latitude first unless told
      # otherwise; RGeo, like WKT, puts longitude first.
      LONGITUDE_FIRST_SRID = 4326

      def quote(value)
        geometry = value.try(:value_for_database) || value
        return super unless RGeo::Feature::Geometry.check_type(geometry)

        arguments = [super(wkt(geometry)), geometry.srid]
        arguments << "'axis-order=long-lat'" if geometry.srid == LONGITUDE_FIRST_SRID
        "ST_GeomFromText(#{arguments.join(', ')})"
      end

    private

      def wkt(geometry)
        RGeo::WKRep::WKTGenerator.new(tag_format: :wkt11, emit_ewkt_srid: false).generate(geometry)
      end
    end
  end
end
