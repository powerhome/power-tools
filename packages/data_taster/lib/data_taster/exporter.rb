# frozen_string_literal: true

module DataTaster
  class Exporter
    BATCH_SIZE = 100

    def serve!
      output.begin_export!(source: source)
      DataTaster.confection.keys.each { |table_name| export_table(table_name) }
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

    def export_table(table_name)
      collection = DataTaster::Collection.new(table_name)
      payload = collection.assemble

      return write_drop_table(table_name) if payload.empty? && output.export_mode == :database

      if output.export_mode == :database
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
      safe_table_name = quote_ident(table_name)

      export_data(collection, safe_table_name)
      DataTaster::Sanitizer.new(table_name, payload[:sanitize]).update_sql_statements.each do |stmt|
        output.write_statement(stmt)
      end
    end

    def export_data(collection, safe_table_name)
      result = source.query(collection.export_select_sql)

      columns = result.fields
      return if columns.empty?

      process_export_in_batches(columns, result, safe_table_name)
    end

    def process_export_in_batches(columns, result, safe_table_name)
      batch = []
      result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(columns, batch, safe_table_name)
          batch.clear
        end
      end
      write_export_batch(columns, batch, safe_table_name) if batch.any?
    end

    def write_drop_table(table_name)
      name = output.export_mode == :file ? output.qualified_table_name(table_name) : table_name
      output.write_statement("DROP TABLE IF EXISTS #{name}")
    end

    def write_export_batch(columns, rows, safe_table_name)
      return if rows.empty?

      col_list = columns.map { |c| quote_ident(c) }.join(", ")
      tuples = rows.map { |row| format_row_tuple(columns, row) }
      output.write_raw("INSERT INTO #{safe_table_name} (#{col_list}) VALUES")
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
