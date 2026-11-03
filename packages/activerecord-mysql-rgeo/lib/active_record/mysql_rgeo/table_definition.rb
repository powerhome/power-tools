# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Builds spatial column definitions for create_table, add_column and
    # change_column. Prepended to MySQL::TableDefinition; other columns are
    # left to Rails.
    module TableDefinition # :nodoc:
      # Rails builds every column definition here:
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/mysql/schema_definitions.rb#L72
      def new_column_definition(name, type, **options)
        spatial = SpatialColumnOptions.build(type, options)
        return super unless spatial

        # The SRID is set after Rails validates the options, so srid: stays an
        # unknown option for every other column.
        super(name, spatial.type, **spatial.options).tap do |definition|
          definition.options[:srid] = spatial.srid if spatial.srid
        end
      end
    end
  end
end
