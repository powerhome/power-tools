# frozen_string_literal: true

module DataTaster
  class FileOutput < Output
    attr_reader :path, :target_database

    def sample!
      start_export

      process_export

      finish_export
    end

    def default_data
      {}
    end

    def run_sanitization?
      false
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

      insert_table_name = ExportContext.quote_ident(table_name)
      Sanitizer.new(table_name, payload[:sanitize]).export_sanitized_rows(
        collection,
        insert_table_name: insert_table_name
      ) { |header, values| write_sanitized_insert(header, values) }
    end

    def table_names
      DataTaster.confection.keys
    end

    def write_sanitized_insert(header, values)
      write_raw(header)
      write_raw("#{values};")
    end
  end
end
