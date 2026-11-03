# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Encodes a spatial column's default the way activerecord-mysql2rgeo-adapter
    # stores it in the column comment: little-endian hex WKB, with the SRID
    # added (EWKB style) for geographic columns.
    module SpatialDefault # :nodoc:
      EWKB_SRID_FLAG = 0x20000000

    module_function

      # +details+ are the column's geographic:, has_z: and has_m: settings.
      def hex(default, geo_type:, srid:, **details)
        geographic = details[:geographic]
        type = Type::Spatial.new(
          geographic ? "geography" : "geometry",
          geo_type: Type::Spatial.normalize_geo_type(geo_type), srid: srid, **details
        )
        wkb = RGeo::WKRep::WKBGenerator.new(hex_format: true, little_endian: true, type_format: :wkb11)
                                       .generate(type.serialize(default)).upcase
        geographic ? with_srid(wkb, srid) : wkb
      end

      # Sets the SRID flag on the WKB type code and inserts the SRID after it.
      def with_srid(wkb, srid)
        type_code = [wkb[2, 8]].pack("H*").unpack1("V") | EWKB_SRID_FLAG
        "#{wkb[0, 2]}#{hex_uint32(type_code)}#{hex_uint32(srid.to_i)}#{wkb[10..]}"
      end

      def hex_uint32(value)
        [value].pack("V").unpack1("H*").upcase
      end
    end
  end
end
