# frozen_string_literal: true

module DataTaster
  class DatabaseOutput < Output
    attr_reader :client

    def initialize(client:, execute: true)
      super()
      @client = client
      @execute = execute
    end

    def target_database
      client.query_options[:database]
    end

    def executes?
      @execute
    end

    def database_export?
      true
    end

    def write_statement(sql)
      return DataTaster.logger.info(sql) unless executes?

      DataTaster.safe_execute(sql, client)
    end

    def write_raw(line)
      write_statement(line)
    end
  end
end
