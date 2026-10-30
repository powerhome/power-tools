# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Parses the string forms a geometry can take: MySQL's internal format,
    # WKT, EWKT, hex WKB and hex EWKB. Returns nil for anything else.
    class GeometryParser # :nodoc:
      SRID_PARAMETER = /(?:srid|SRID)=\d*/

      # +default_srid+ applies when the string carries no SRID. The block
      # returns the RGeo factory to build a geometry with a given SRID.
      def initialize(default_srid, &factory_for)
        @default_srid = default_srid
        @factory_for = factory_for
      end

      def parse(string)
        if mysql_internal_format?(string)
          parse_mysql_internal_format(string)
        elsif string.match?(/\A[0-9a-fA-F]+\z/)
          parse_hex_wkb(string)
        else
          parse_ewkt(string)
        end
      rescue RGeo::Error::ParseError, RGeo::Error::InvalidGeometry
        nil
      end

    private

      # MySQL returns geometries as a 4-byte SRID followed by WKB, whose
      # first byte is the byte order (0 or 1).
      def mysql_internal_format?(string)
        ["\x00", "\x01"].include?(string[4, 1])
      end

      def parse_mysql_internal_format(string)
        srid = string[0, 4].unpack1(string[4, 1] == "\x01" ? "V" : "N")
        wkb_parser(srid).parse(string[4..])
      end

      def parse_hex_wkb(string)
        wkb_parser(@default_srid).parse([string].pack("H*"))
      rescue RGeo::Error::ParseError, RGeo::Error::InvalidGeometry
        raise unless string[0, 10].match?(/[0-9a-fA-F]{8}0[01]/)

        parse_srid_prefixed_hex_wkb(string)
      end

      # Hex of MySQL's internal format: an SRID followed by WKB.
      def parse_srid_prefixed_hex_wkb(string)
        srid = string[0, 8].to_i(16)
        srid = [srid].pack("V").unpack1("N") if string[9, 1] == "1"
        wkb_parser(srid).parse([string[8..]].pack("H*"))
      end

      def parse_ewkt(string)
        wkt, srid = split_srid(string)
        srid = @default_srid if srid.zero?
        RGeo::WKRep::WKTParser.new(@factory_for.call(srid), support_ewkt: true, default_srid: srid).parse(wkt)
      end

      def wkb_parser(srid)
        RGeo::WKRep::WKBParser.new(@factory_for.call(srid), support_ewkb: true, default_srid: srid)
      end

      # "SRID=4326;POINT(1 2)" => ["POINT(1 2)", 4326]. Like the upstream
      # gem, only the first and last parts are read, and the last one wins.
      def split_srid(string)
        return [string, 0] unless string.include?(";")

        srid_parts, wkt_parts = string.split(";").values_at(0, -1).partition do |part|
          part.match?(SRID_PARAMETER)
        end
        [wkt_parts.last, srid_parts.last&.split("=")&.last.to_i]
      end
    end
  end
end
