# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Spatial details a MySQL column definition can't hold, kept as markers
    # in the column comment, in the format activerecord-mysql2rgeo-adapter
    # writes: "Where it is mysql2rgeo:geographic".
    class ColumnMetadata # :nodoc:
      GEOGRAPHIC = "mysql2rgeo:geographic"
      HAS_Z = "mysql2rgeo:has_z"
      HAS_M = "mysql2rgeo:has_m"
      DEFAULT_PREFIX = "mysql2rgeo:default:"
      DEFAULT = /#{DEFAULT_PREFIX}([0-9A-Fa-f]+)/
      MARKERS = /mysql2rgeo:(?:geographic|has_z|has_m|array|default:[0-9A-Fa-f]+)/

      # +comment+ followed by the markers for the given details, in the order
      # activerecord-mysql2rgeo-adapter writes them. +default+ is hex WKB.
      def self.annotate(comment, geographic: false, has_z: false, has_m: false, default: nil)
        markers = [comment.presence]
        markers << GEOGRAPHIC if geographic
        markers << HAS_M if has_m
        markers << HAS_Z if has_z
        markers << "#{DEFAULT_PREFIX}#{default}" if default
        markers.compact.join(" ").presence
      end

      def initialize(comment)
        @text = comment.to_s
      end

      # The comment as written by people, without markers.
      def comment
        @text.gsub(MARKERS, "").squeeze(" ").strip.presence
      end

      def geographic?
        @text.include?(GEOGRAPHIC)
      end

      def z?
        @text.include?(HAS_Z)
      end

      def m?
        @text.include?(HAS_M)
      end

      # The column default, as hex WKB.
      def default
        @text[DEFAULT, 1]
      end
    end
  end
end
