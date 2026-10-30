# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Spatial additions to the MySQL adapters' schema statements. Prepended to
    # AbstractMysqlAdapter; every method leaves non-spatial columns to Rails.
    module SchemaStatements # :nodoc:
      # <tt>using: :gist</tt> creates a spatial index. MySQL only indexes
      # NOT NULL spatial columns, so nullable ones are made NOT NULL first,
      # as activerecord-mysql2rgeo-adapter does.
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L456
      def add_index(table_name, column_name, **options)
        make_spatial_columns_not_null(table_name, column_name) if options[:using].to_s == "gist"
        super
      end

    private

      def make_spatial_columns_not_null(table_name, column_names)
        Array(column_names).each do |name|
          column = columns(table_name).find { |c| c.name == name.to_s }
          change_column_null(table_name, name, false) if column.is_a?(SpatialColumn) && column.null
        end
      end

      # Rails builds a column from each row of SHOW FULL FIELDS here:
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/mysql/schema_statements.rb#L184
      def new_column_from_field(table_name, field, definitions)
        column = super
        return column unless column.type == :geometry

        spatial_column(table_name, column)
      end

      def spatial_column(table_name, column)
        metadata = ColumnMetadata.new(column.comment)
        sql_type = spatial_sql_type(table_name, column, metadata)
        SpatialColumn.from(
          column,
          sql_type_metadata: spatial_type_metadata(column, sql_type),
          cast_type: lookup_cast_type(sql_type),
          comment: metadata.comment,
          default: column.default.nil? ? metadata.default : column.default
        )
      end

      def spatial_sql_type(table_name, column, metadata)
        SpatialColumn.sql_type_for(
          column.sql_type,
          srid: column_srid(table_name, column.name),
          geographic: metadata.geographic?,
          has_z: metadata.z?,
          has_m: metadata.m?
        )
      end

      def spatial_type_metadata(column, sql_type)
        ConnectionAdapters::MySQL::TypeMetadata.new(
          ConnectionAdapters::SqlTypeMetadata.new(sql_type: sql_type, type: :geometry),
          extra: column.sql_type_metadata.extra
        )
      end

      # SHOW FULL FIELDS doesn't report a column's SRID attribute.
      # quoted_scope is private in Rails too:
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/mysql/schema_statements.rb#L251
      def column_srid(table_name, column_name)
        scope = quoted_scope(table_name)
        query_value(<<~SQL.squish, "SCHEMA").to_i
          SELECT srs_id FROM information_schema.columns
          WHERE table_schema = #{scope[:schema]}
            AND table_name = #{scope[:name]}
            AND column_name = #{quote(column_name)}
        SQL
      end
    end
  end
end
