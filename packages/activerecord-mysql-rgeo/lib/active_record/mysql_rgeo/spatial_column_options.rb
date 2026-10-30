# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Turns the type and options a migration gives a spatial column into the
    # MySQL type and the options Rails builds the column definition from:
    #
    #   t.st_point :location, geographic: true, default: "POINT(1 2)"
    #   # => type :point, srid 4326, comment: "mysql2rgeo:geographic mysql2rgeo:default:..."
    #
    # The options can also come in a limit hash, as schema.rb writes them, or
    # in a sql_type such as "geometry(Point,3857)", as change_column passes it.
    class SpatialColumnOptions # :nodoc:
      # The type names migrations accept, and the MySQL type each creates.
      MYSQL_TYPES = {
        "geometry" => "geometry", "geography" => "geometry", "spatial" => "geometry",
        "point" => "point", "st_point" => "point",
        "polygon" => "polygon", "st_polygon" => "polygon",
        "linestring" => "linestring", "line_string" => "linestring",
        "multipoint" => "multipoint", "multi_point" => "multipoint",
        "multilinestring" => "multilinestring", "multi_line_string" => "multilinestring",
        "multipolygon" => "multipolygon", "multi_polygon" => "multipolygon",
        "geometrycollection" => "geometrycollection", "geometry_collection" => "geometrycollection",
        "geomcollection" => "geometrycollection"
      }.freeze
      SQL_TYPE = /\A(?:geometry|geography)\(/i
      # Kept in the column comment rather than the column definition.
      DETAILS = %i[geographic has_z has_m].freeze

      # Returns nil unless +type+ (or, for virtual columns, options[:type])
      # is spatial.
      def self.build(type, options)
        requested = type == :virtual ? options[:type] : type
        return unless MYSQL_TYPES.key?(requested.to_s.downcase) || SQL_TYPE.match?(requested.to_s)

        new(type, requested, options)
      end

      # +srid+ is nil for virtual columns. It is kept apart from +options+, which
      # Rails validates, so other columns still reject an srid: option.
      attr_reader :type, :srid, :options

      def initialize(type, requested, options)
        @options = options.dup
        @options.merge!(@options.delete(:limit)) if @options[:limit].is_a?(Hash)
        if type == :virtual
          build_virtual
        else
          build_stored(requested)
        end
      end

    private

      # activerecord-mysql2rgeo-adapter creates generated spatial columns as
      # plain GEOMETRY, without SRID or markers.
      def build_virtual
        @type = :virtual
        @options[:type] = :geometry
        @options.except!(:srid, :geographic, :has_z, :has_m)
      end

      def build_stored(requested)
        name, parsed = parse(@options.delete(:type) || requested)
        @type = (MYSQL_TYPES[name] || MYSQL_TYPES.fetch(requested.to_s.downcase, "geometry")).to_sym
        details = extract_details(name, parsed)
        @srid = @options.delete(:srid) || parsed[:srid] || (details[:geographic] ? 4326 : 0)
        @options[:comment] = ColumnMetadata.annotate(@options[:comment], **details, default: spatial_default(details))
      end

      # geographic:, has_z: and has_m:, from the options or the sql_type.
      def extract_details(name, parsed)
        details = DETAILS.index_with { |key| @options.delete(key) || parsed.fetch(key, false) }
        details[:geographic] ||= name == "geography"
        details
      end

      # The type name, plus what a "geometry(PointZ,3857)" sql_type says.
      def parse(type)
        return [type.to_s.downcase, {}] unless SQL_TYPE.match?(type.to_s)

        geo_type, srid, has_z, has_m, geographic = Type::Spatial.parse_sql_type(type.to_s)
        [geo_type.to_s.downcase, { srid: srid, has_z: has_z, has_m: has_m, geographic: geographic }]
      end

      # MySQL can't give spatial columns a literal default, so it is kept in
      # the comment. Expression defaults (procs) stay in the column.
      def spatial_default(details)
        default = @options[:default]
        return if default.nil? || default.respond_to?(:call)

        @options.delete(:default)
        SpatialDefault.hex(default, geo_type: @type.to_s, srid: @srid, **details)
      end
    end
  end
end
