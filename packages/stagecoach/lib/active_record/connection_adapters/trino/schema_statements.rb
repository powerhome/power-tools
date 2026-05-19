# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Trino
      module SchemaStatements
        def columns(table_name)
          rows = run_trino_query(columns_query(table_name.to_s)).rows
          rows.map do |name, data_type, is_nullable|
            Trino::Column.new(
              name: name,
              sql_type: data_type,
              type: type_map.lookup(data_type),
              null: nullable?(is_nullable)
            )
          end
        end

        def data_sources
          run_trino_query("SHOW TABLES").rows.map(&:first)
        end
        alias tables data_sources

        def table_exists?(table_name)
          data_sources.include?(table_name.to_s)
        end
        alias data_source_exists? table_exists?

        def primary_key(_table_name)
          nil
        end

        def indexes(_table_name)
          []
        end

        def foreign_keys(_table_name)
          []
        end

        def views
          []
        end

        def view_exists?(_view_name)
          false
        end

        def schema_cache
          @schema_cache ||= ActiveRecord::ConnectionAdapters::SchemaCache.new(self)
        end

      private

        def columns_query(table_name)
          <<~SQL.strip
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_catalog = #{quote(trino_catalog)}
              AND table_schema = #{quote(trino_schema)}
              AND table_name = #{quote(table_name)}
            ORDER BY ordinal_position
          SQL
        end

        def trino_catalog
          @client_options[:catalog]
        end

        def trino_schema
          @client_options[:schema]
        end

        def nullable?(value)
          value.to_s.casecmp?("yes")
        end
      end
    end
  end
end
