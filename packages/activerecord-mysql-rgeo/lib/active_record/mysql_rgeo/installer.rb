# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # The only place where this gem changes Rails classes. It runs from the
    # load hooks of the trilogy and mysql2 adapters, so it never loads a driver
    # itself, and works whether the gem is required before or after them.
    module Installer # :nodoc:
      MUTEX = Mutex.new

      class << self
        # +adapter+ is the name database.yml uses for +adapter_class+, which
        # the attribute API looks types up by.
        def install(adapter_class, adapter:)
          MUTEX.synchronize do
            ConflictingGemError.check!
            install_into_abstract_mysql_adapter
            # Rails built this adapter's TYPE_MAP before running its load hook.
            TypeMap.register(adapter_class::TYPE_MAP) unless TypeMap.registered?(adapter_class::TYPE_MAP)
            AttributeTypes.register(adapter)
          end
        end

      private

        # Shared by every MySQL adapter class, including those other gems
        # derive from trilogy or mysql2.
        def install_into_abstract_mysql_adapter
          adapter = ConnectionAdapters::AbstractMysqlAdapter
          return if adapter.singleton_class.include?(TypeMap)

          adapter.singleton_class.prepend(TypeMap)
          adapter.prepend(SchemaStatements)
          adapter.prepend(Quoting)
          ConnectionAdapters::MySQL::Column.include(Column)
          (NativeDatabaseTypes::CLASS_METHOD ? adapter.singleton_class : adapter).prepend(NativeDatabaseTypes)
          install_into_migrations
          install_into_arel
        end

        def install_into_arel
          Arel::Visitors::MySQL.prepend(ArelVisitor)
          # Ruby adds the methods to Arel attributes, Arel.spatial constants
          # and spatial functions, which already include SpatialExpressions.
          RGeo::ActiveRecord::SpatialExpressions.include(SpatialExpressions)
        end

        def install_into_migrations
          mysql = ConnectionAdapters::MySQL
          mysql::TableDefinition.prepend(TableDefinition)
          mysql::TableDefinition.include(ColumnMethods)
          mysql::Table.include(ColumnMethods)
          mysql::SchemaCreation.prepend(SchemaCreation)
          mysql::SchemaDumper.prepend(SchemaDumper)
        end
      end
    end
  end
end
