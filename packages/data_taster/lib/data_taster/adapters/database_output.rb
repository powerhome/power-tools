# frozen_string_literal: true

module DataTaster
  class DatabaseOutput < Output
    attr_reader :client

    def initialize(client:)
      super()
      @client = client
    end

    def export_mode
      :database
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
  end
end
