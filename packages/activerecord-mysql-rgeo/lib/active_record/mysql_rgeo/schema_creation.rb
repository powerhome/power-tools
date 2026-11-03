# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Spatial SQL for migrations: the SRID column attribute and spatial
    # indexes. Prepended to MySQL::SchemaCreation; other columns and indexes
    # are left to Rails.
    module SchemaCreation # :nodoc:
    private

      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/mysql/schema_creation.rb#L42
      def visit_IndexDefinition(index, create = false)
        return super unless index.using.to_s == "gist"

        sql = create ? ["CREATE SPATIAL INDEX"] : ["SPATIAL INDEX"]
        sql << quote_column_name(index.name)
        sql << "ON #{quote_table_name(index.table)}" if create
        sql << "(#{quoted_columns(index)})"
        add_sql_comment!(sql.join(" "), index.comment)
      end

      # The SRID attribute follows the type, before NULL, DEFAULT and COMMENT.
      # The version comment keeps the SQL valid on MySQL older than 8.0.3, as
      # activerecord-mysql2rgeo-adapter writes it.
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/connection_adapters/mysql/schema_creation.rb#L62
      def add_column_options!(sql, options)
        sql << " /*!80003 SRID #{options[:srid]} */" if options[:srid]
        super
      end
    end
  end
end
