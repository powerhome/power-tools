# frozen_string_literal: true

module DataTaster
  # Selects and sanitizes tables from the source_db to write to a SQL file on disk.
  class SampleToSql
    BATCH_SIZE = 100

    def initialize
      @source_client = DataTaster.config.source_client
    end

    def serve!
      path = temp_file_path
      File.open(path, "w") do |io|
        io.puts "SET FOREIGN_KEY_CHECKS=0;"
        DataTaster
          .confection.keys
          .each do |table_name|
            write_to_sql_file(io, table_name)
          end
        io.puts "SET FOREIGN_KEY_CHECKS=1;"
      end
      path
    end

  private

    attr_reader :source_client

    def write_to_sql_file(io, table_name)
      safe_db_name = quote_ident(DataTaster.target_database)
      safe_table_name = quote_ident(table_name)

      binding.pry

      collection = DataTaster::Collection.new(table_name)
      payload = collection.assemble

      # Any table that does not return SQL is considered deprecated and we should fully skip it
      if payload.empty? && DataTaster.config.include_insert
        DataTaster.safe_execute("DROP TABLE IF EXISTS #{table_name}", source_client)
        return
      end

      export_data(io, collection, safe_db_name, safe_table_name)
      sanitize_data(io, table_name, payload[:sanitize])
    end

    def export_data(io, collection, safe_db_name, safe_table_name)
      select_sql = collection.export_select_sql
      result = source_client.query(select_sql)

      columns = result.fields
      return if columns.empty?

      process_export_in_batches(io, columns, result, safe_db_name, safe_table_name)
    end

    def process_export_in_batches(io, columns, result, safe_db_name, safe_table_name)
      batch = []
      result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(io, columns, batch, safe_db_name, safe_table_name)
          batch.clear
        end
      end
      write_export_batch(io, columns, batch, safe_db_name, safe_table_name) if batch.any?
    end

    def sanitize_data(io, table_name, sanitize)
      DataTaster::Sanitizer.new(table_name, sanitize).update_sql_statements.each do |stmt|
        io.puts "#{stmt};"
      end
    end

    def quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end

    def write_export_batch(io, columns, rows, safe_db_name, safe_table_name)
      return if rows.empty?

      col_list = columns.map { |c| quote_ident(c) }.join(", ")
      tuples = rows.map do |row|
        "(#{columns.map { |c| DataTaster::SqlLiteral.format(source_client, row[c]) }.join(', ')})"
      end
      io.puts "INSERT INTO #{safe_db_name}.#{safe_table_name} (#{col_list}) VALUES"
      io.puts "#{tuples.join(",\n")};"
    end

    def temp_file_path
      filename = "data_taster_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.sql"
      File.join(Rails.root, "tmp", filename).to_s
    end
  end
end
