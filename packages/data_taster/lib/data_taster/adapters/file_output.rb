# frozen_string_literal: true

module DataTaster
  class FileOutput < Output
    BATCH_SIZE = 100

    attr_reader :path, :target_database

    def sample!
      start_export

      process_export
      
      finish_export
    end

    def export_mode
      :file
    end

    def qualified_table_name(table_name)
      "`#{table_name.to_s.gsub('`', '``')}`"
    end

    def write_statement(sql)
      @io.puts "#{sql};"
    end

    def write_raw(line)
      @io.puts line
    end

  private

    def process_export
      table_names.each do |table_name|
        collection = DataTaster::Collection.new(table_name)
        export_table(collection, table_name)
      end
    end

    def start_export
      DataTaster.logger.info("Writing SQL file to #{path}")
      @io = File.open(path, "w")
      @io.puts "SET FOREIGN_KEY_CHECKS=0;"
    end

    def finish_export
      @io.puts "SET FOREIGN_KEY_CHECKS=1;"
      @io.close
    end

    def export_table(collection, table_name)
      payload = collection.assemble
      return if payload.empty?

      safe_table_name = quote_ident(table_name)
      export_data(collection, safe_table_name)
      sanitize_data(table_name, payload[:sanitize])
    end

    def table_names
      DataTaster.confection.keys
    end

    def source
      DataTaster.config.source
    end

    def export_data(collection, safe_table_name)
      result = source.query(collection.export_select_sql)

      columns = result.fields
      return if columns.empty?

      process_export_in_batches(columns, result, safe_table_name)
    end

    def sanitize_data(table_name, sanitize)
      DataTaster::Sanitizer.new(table_name, sanitize).update_sql_statements.each do |stmt|
        write_statement(stmt)
      end
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

    def write_export_batch(columns, rows, safe_table_name)
      return if rows.empty?

      col_list = columns.map { |c| quote_ident(c) }.join(", ")
      tuples = rows.map { |row| format_row_tuple(columns, row) }
      write_raw("INSERT INTO #{safe_table_name} (#{col_list}) VALUES")
      write_raw("#{tuples.join(",\n")};")
    end

    def format_row_tuple(columns, row)
      "(#{columns.map { |c| DataTaster::SqlLiteral.format(source.client, row[c]) }.join(', ')})"
    end

    def quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end
  end
end
