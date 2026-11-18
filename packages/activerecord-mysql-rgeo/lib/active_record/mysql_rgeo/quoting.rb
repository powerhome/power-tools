# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Writes RGeo geometries as SQL. Prepended to AbstractMysqlAdapter; any
    # other value is quoted by Rails.
    module Quoting # :nodoc:
      # MySQL reads SRID 4326 coordinates latitude first unless told
      # otherwise; RGeo, like WKT, puts longitude first.
      LONGITUDE_FIRST_SRID = 4326

      # The SQL that builds a geometry from +quoted_wkt+ with +srid+.
      def self.geometry_from_text(quoted_wkt, srid)
        arguments = [quoted_wkt, srid]
        arguments << "'axis-order=long-lat'" if srid == LONGITUDE_FIRST_SRID
        "ST_GeomFromText(#{arguments.join(', ')})"
      end

      def quote(value)
        geometry = value.try(:value_for_database) || value
        return super unless RGeo::Feature::Geometry.check_type(geometry)

        Quoting.geometry_from_text(super(wkt(geometry)), geometry.srid)
      end

    private

      def wkt(geometry)
        RGeo::WKRep::WKTGenerator.new(tag_format: :wkt11, emit_ewkt_srid: false).generate(geometry)
      end
    end
  end
end
