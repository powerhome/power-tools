# frozen_string_literal: true

module DataTaster
  class MysqlSource
    attr_reader :client

    def initialize(client:)
      @client = client
    end

    def query(sql)
      client.query(sql)
    end

    def database
      client.query_options[:database]
    end

    def table_names
      query("SHOW tables").map { |row| row[row.keys.first] }
    end
  end
end
