# frozen_string_literal: true

module DataTaster
  class DatabaseOutput < Output
    attr_reader :client

    def export_mode
      :database
    end

    def sample!
      source = DataTaster.config.source
      table_names(source).each do |table_name|
        collection = DataTaster::Collection.new(table_name)
        export_table(collection, table_name)
      end
    end

    def export_table(collection, table_name)
      payload = collection.assemble
      return write_drop_table(table_name) if payload.empty?

      export(collection, table_name, payload)
    end

    def target_database
      client.query_options[:database]
    end

    def table_names(source)
      source.table_names
    end

    def qualified_table_name(table_name)
      "#{target_database}.#{table_name}"
    end

    def write_statement(sql)
      DataTaster.safe_execute(sql, client)
    end

    def write_raw(line)
      write_statement(line)
    end

  private

    def export(_collection, table_name, payload)
      write_statement("TRUNCATE TABLE #{target_database}.#{table_name}")
      write_statement(payload[:select])
      DataTaster::Sanitizer.new(table_name, payload[:sanitize]).clean!
    end

    def write_drop_table(table_name)
      write_statement("DROP TABLE IF EXISTS #{table_name}")
    end
  end
end
