# frozen_string_literal: true

module DataTaster
  class DatabaseOutput < Output
    attr_reader :target_client

    def sample!
      source = DataTaster.config.source
      table_names(source).each do |table_name|
        collection = DataTaster::Collection.new(table_name)
        import_table(collection, table_name)
      end
    end

    def run_sanitization?
      true
    end

    def default_data
      { "schema_migrations" => "1 = 1" }
    end

    def import_table(collection, table_name)
      payload = collection.assemble
      return write_drop_table(table_name) if payload.empty?

      export(collection, table_name, payload)
    end

    def target_database
      target_client.query_options[:database]
    end

    def qualified_table_name(table_name)
      "#{target_database}.#{table_name}"
    end

    def write_statement(sql)
      safe_execute(sql)
    end

    def write_raw(line)
      write_statement(line)
    end

  private

    def safe_execute(sql)
      foreign_key_check = target_client.query("SELECT @@FOREIGN_KEY_CHECKS").first["@@FOREIGN_KEY_CHECKS"]

      begin
        target_client.query("SET FOREIGN_KEY_CHECKS=0")
        target_client.query(sql)
      ensure
        target_client.query("SET FOREIGN_KEY_CHECKS=#{foreign_key_check};")
      end
    end

    def table_names(source)
      source.table_names
    end

    def export(collection, table_name, payload)
      write_statement("TRUNCATE TABLE #{qualified_table_name(table_name)}")
      insert_table_name = "#{ExportContext.quote_ident(target_database)}.#{ExportContext.quote_ident(table_name)}"
      Sanitizer.new(table_name, payload[:sanitize]).export_sanitized_rows(
        collection,
        insert_table_name: insert_table_name
      ) { |header, values| write_sanitized_insert(header, values) }
    end

    def write_drop_table(table_name)
      write_statement("DROP TABLE IF EXISTS #{qualified_table_name(table_name)}")
    end

    def write_sanitized_insert(header, values)
      write_statement("#{header} #{values}")
    end
  end
end
