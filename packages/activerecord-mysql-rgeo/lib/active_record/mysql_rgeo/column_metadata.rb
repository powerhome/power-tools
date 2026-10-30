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
      MARKERS = /mysql2rgeo:(?:geographic|has_z|has_m|array|default:[0-9A-Fa-f]+)/

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
    end
  end
end
