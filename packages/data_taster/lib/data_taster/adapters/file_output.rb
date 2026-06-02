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
      DataTaster::ExportContext.quote_ident(table_name)
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

      @export_context = DataTaster::ExportContext.new(table_name, payload[:sanitize])

      query_result = source.query(collection.export_select_sql)

      columns = query_result.fields
      return if columns.empty?

      process_export_in_batches(columns, query_result)
    end

    def table_names
      DataTaster.confection.keys
    end

    def source
      DataTaster.config.source
    end

    def process_export_in_batches(columns, query_result)
      batch = []
      query_result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(columns, batch)
          batch.clear
        end
      end
      write_export_batch(columns, batch) if batch.any?
    end

    def write_export_batch(columns, batches)
      return if batches.empty?

      client = source.client
      col_list = columns.map { |c| DataTaster::ExportContext.quote_ident(c) }.join(", ")
      tuples = batches.map { |batch| @export_context.format_row_tuple(columns, batch, client) }
      write_raw("INSERT INTO #{@export_context.safe_table_name} (#{col_list}) VALUES")
      write_raw("#{tuples.join(",\n")};")
    end
  end
end
