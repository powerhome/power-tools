# frozen_string_literal: true

module DataTaster
  # Selects and sanitizes tables from the source database, writing results
  # through the configured output adapter (database or SQL file).
  class Exporter
    BATCH_SIZE = 100

    def serve!
      output.begin_export!(source: source)
      table_names.each { |table_name| export_table(table_name) }
      output.finish_export!
    end

  private

    def config
      DataTaster.config
    end

    def source
      config.source
    end

    def output
      config.output
    end

    def table_names
      if output.file_export?
        DataTaster.confection.keys
      else
        source.table_names
      end
    end

    def export_table(table_name)
      collection = DataTaster::Collection.new(table_name)
      payload = collection.assemble

      return write_drop_table(table_name) if payload.empty? && output.executes?

      if output.database_export?
        export_to_database(payload, table_name)
      else
        export_to_file(collection, table_name, payload)
      end
    end

    def export_to_database(payload, table_name)
      output.write_statement("TRUNCATE TABLE #{target_database}.#{table_name}")
      output.write_statement(payload[:select])
      DataTaster::Sanitizer.new(table_name, payload[:sanitize]).clean!
    end

    def export_to_file(collection, table_name, payload)
      safe_db_name = quote_ident(target_database)
      safe_table_name = quote_ident(table_name)

      export_data(collection, safe_db_name, safe_table_name)
      sanitize_data(table_name, payload[:sanitize])
    end

    def export_data(collection, safe_db_name, safe_table_name)
      result = source.query(collection.export_select_sql)

      columns = result.fields
      return if columns.empty?

      process_export_in_batches(columns, result, safe_db_name, safe_table_name)
    end

    def process_export_in_batches(columns, result, safe_db_name, safe_table_name)
      batch = []
      result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(columns, batch, safe_db_name, safe_table_name)
          batch.clear
        end
      end
      write_export_batch(columns, batch, safe_db_name, safe_table_name) if batch.any?
    end

    def sanitize_data(table_name, sanitize)
      DataTaster::Sanitizer.new(table_name, sanitize).update_sql_statements.each do |stmt|
        output.write_statement(stmt)
      end
    end

    def write_drop_table(table_name)
      if output.file_export?
        safe_db_name = quote_ident(target_database)
        safe_table_name = quote_ident(table_name)
        output.write_statement("DROP TABLE IF EXISTS #{safe_db_name}.#{safe_table_name}")
      else
        output.write_statement("DROP TABLE IF EXISTS #{table_name}")
      end
    end

    def write_export_batch(columns, rows, safe_db_name, safe_table_name)
      return if rows.empty?

      col_list = columns.map { |c| quote_ident(c) }.join(", ")
      tuples = rows.map { |row| format_row_tuple(columns, row) }
      output.write_raw("INSERT INTO #{safe_db_name}.#{safe_table_name} (#{col_list}) VALUES")
      output.write_raw("#{tuples.join(",\n")};")
    end

    def format_row_tuple(columns, row)
      "(#{columns.map { |c| DataTaster::SqlLiteral.format(source.client, row[c]) }.join(', ')})"
    end

    def quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end

    def target_database
      output.target_database
    end
  end
end
