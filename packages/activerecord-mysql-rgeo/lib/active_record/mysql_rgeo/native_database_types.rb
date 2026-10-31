# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Adds the spatial type names to the adapter's native types, which
    # migrations and the schema dumper (valid_type?) look types up in.
    # Prepended to AbstractMysqlAdapter, or to its singleton class from
    # Active Record 8.1.
    module NativeDatabaseTypes # :nodoc:
      # Active Record 8.1 moved native_database_types to the adapter class:
      # https://github.com/rails/rails/blob/v8.1.4/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L92
      # Before, it was an instance method:
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L189
      CLASS_METHOD = ActiveRecord.gem_version >= Gem::Version.new("8.1.0.alpha")

      TYPES = SpatialColumnOptions::MYSQL_TYPES.to_h { |name, sql_name| [name.to_sym, { name: sql_name }] }.freeze

      def native_database_types
        super.merge(TYPES)
      end
    end
  end
end
