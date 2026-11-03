# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Maps MySQL's spatial column types to Type::Spatial.
    #
    # Prepended to the singleton class of AbstractMysqlAdapter, so adapter
    # classes that build their TYPE_MAP afterwards include spatial types.
    # TYPE_MAPs built before the gem loaded get them through TypeMap.register.
    module TypeMap # :nodoc:
      # Type names used by migrations and the attribute API, and the geometric
      # type each one stands for.
      NAMED_TYPES = {
        "geography" => "geometry",
        "geometry" => "geometry",
        "geometry_collection" => "geometrycollection",
        "line_string" => "linestring",
        "multi_line_string" => "multilinestring",
        "multi_point" => "multipoint",
        "multi_polygon" => "multipolygon",
        "st_point" => "point",
        "st_polygon" => "polygon",
      }.freeze

      # SQL types reported by MySQL, plus the geometry(...) and geography(...)
      # forms spatial columns describe themselves with.
      SQL_TYPES = [
        /\Ageometry(?:\(.*\))?\z/i,
        /\Ageography(?:\(.*\))?\z/i,
        /\Apoint(?:\s.*)?\z/i,
        /\Alinestring(?:\s.*)?\z/i,
        /\Apolygon(?:\s.*)?\z/i,
        /\Amultipoint(?:\s.*)?\z/i,
        /\Amultilinestring(?:\s.*)?\z/i,
        /\Amultipolygon(?:\s.*)?\z/i,
        /\Ageometrycollection(?:\s.*)?\z/i,
      ].freeze

      # MySQL 8 reports GEOMETRYCOLLECTION columns as "geomcollection".
      GEOMCOLLECTION = /\Ageomcollection(?:\s.*)?\z/i

      def self.register(type_map)
        NAMED_TYPES.each do |name, geo_type|
          type_map.register_type(name) { |sql_type| Type::Spatial.new(sql_type.to_s, geo_type: geo_type) }
        end
        SQL_TYPES.each do |pattern|
          type_map.register_type(pattern) { |sql_type| Type::Spatial.new(sql_type.to_s) }
        end
        type_map.register_type(GEOMCOLLECTION) do |sql_type|
          Type::Spatial.new(sql_type.to_s, geo_type: "geometry_collection")
        end
      end

      def self.registered?(type_map)
        type_map.lookup("geometry").is_a?(Type::Spatial)
      end

    private

      # Rails builds each adapter's TYPE_MAP with this class method:
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L722
      def initialize_type_map(type_map)
        super
        TypeMap.register(type_map)
      end
    end
  end
end
