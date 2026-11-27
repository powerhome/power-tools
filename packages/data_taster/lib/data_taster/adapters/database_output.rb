# frozen_string_literal: true

module DataTaster
  class DatabaseOutput < Output
    attr_reader :target_client

    def initialize(target_client:, **options)
      super(target_client: Adapters.wrap(target_client), **options)
    end

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

    # When the source and target share a MySQL server, MySQL copies each table itself and DataTaster never holds its
    # rows. Otherwise every row is read into memory and written back as INSERTs, and a large table can use more memory
    # than the process has.
    def copies_on_server?
      source_client = DataTaster.config.source.source_client
      # Checked once per source, since a later DataTaster.setup can pair this output with another source
      return @copies_on_server if @checked_source.equal?(source_client)

      target_server = server_uuid(target_client)
      @checked_source = source_client
      @copies_on_server = target_server.present? && target_server == server_uuid(source_client)
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
      TableOrder.new(source.table_names).to_a
    end

    def server_uuid(client)
      client.query("SELECT @@server_uuid AS server_uuid").first&.fetch("server_uuid", nil)
    rescue
      nil
    end

    def export(collection, table_name, payload)
      write_statement("TRUNCATE TABLE #{qualified_table_name(table_name)}")
      if copies_on_server?
        copy_on_server(collection, table_name, payload)
      else
        export_through_client(collection, table_name, payload)
      end
    end

    # The SELECT runs on the target connection, so a table its WHERE clause names without a database is read from the
    # target: the rows already copied there, not the whole source table. The rows are copied as they are and sanitized
    # afterwards, so a failed sanitization empties the table rather than leave production values in it.
    def copy_on_server(collection, table_name, payload)
      write_statement("INSERT INTO #{qualified_table_name(table_name)} #{collection.export_select_sql}")
      begin
        Sanitizer.new(table_name, payload[:sanitize]).clean!
      rescue
        write_statement("TRUNCATE TABLE #{qualified_table_name(table_name)}")
        raise
      end
    end

    def export_through_client(collection, table_name, payload)
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
