# frozen_string_literal: true

module DataTaster
  class MysqlSource
    attr_reader :source_client

    def initialize(source_client:)
      @source_client = source_client
    end

    def query(sql)
      source_client.query(sql)
    end

    def database
      source_client.query_options[:database]
    end

    def table_names
      query("SHOW tables").map { |row| row[row.keys.first] }
    end
  end
end
