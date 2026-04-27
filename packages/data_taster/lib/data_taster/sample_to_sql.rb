# frozen_string_literal: true

module DataTaster
  # Selects and sanitizes tables from the source_db to write to a SQL file on disk.
  class SampleToSql
    BATCH_SIZE = 100

    def initialize
      @source_client = DataTaster.config.source_client
    end

    def serve!
      File.open(temp_file_path, "w") do |io|
        io.puts "SET FOREIGN_KEY_CHECKS=0;"
        DataTaster
          .confection
          .keys
          .each do |table_name|
            write_to_sql_file(io, table_name)
          end
        io.puts "SET FOREIGN_KEY_CHECKS=1;"
      end
      temp_file_path
    end

  private

    attr_reader :source_client

    def write_to_sql_file(io, table_name)
      safe_db_name = quote_ident(source_db)
      safe_table_name = quote_ident(table_name)

      collection = DataTaster::Collection.new(table_name)
      payload = collection.assemble

      # Any table that does not return SQL is considered deprecated and we should fully skip it
      if payload.empty? && DataTaster.config.include_insert
        DataTaster.safe_execute("DROP TABLE IF EXISTS #{table_name}", source_client)
      else
        select_sql = collection.export_select_sql
        result = source_client.query(select_sql)

        columns = result.fields
        return if columns.empty?

        batch = []
        result.each do |row|
          batch << row
          if batch.size >= BATCH_SIZE
            write_insert_batch(io, columns, batch, safe_db_name, safe_table_name)
            batch.clear
          end
        end

        write_insert_batch(io, columns, batch, safe_db_name, safe_table_name) if batch.any?

        DataTaster::Sanitizer.new(table_name, payload[:sanitize]).update_sql_statements.each do |stmt|
          io.puts "#{stmt};"
        end
      end
    end

    def quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end

    def write_insert_batch(io, columns, rows, td, tn)
      return if rows.empty?

      col_list = columns.map { |c| quote_ident(c) }.join(", ")
      tuples = rows.map do |row|
        "(" + columns.map { |c| DataTaster::SqlLiteral.format(source_client, row[c]) }.join(", ") + ")"
      end
      io.puts "INSERT INTO #{td}.#{tn} (#{col_list}) VALUES"
      io.puts "#{tuples.join(",\n")};"
    end

    def temp_file_path
      filename = "data_taster_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.sql"
      File.join(Rails.root, "tmp", filename).to_s
    end

    def source_db
      @source_db ||= source_client.query_options[:database]
    end
  end
end
