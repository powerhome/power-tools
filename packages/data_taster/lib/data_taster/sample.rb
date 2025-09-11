# frozen_string_literal: true

module DataTaster
  # Selects and processes tables from the source_db
  # to insert (or query) into the working_db
  class Sample
    def initialize(table_name)
      @table_name = table_name
      @include_insert = DataTaster.config.include_insert
      @collection = DataTaster::Collection.new(
        table_name
      ).assemble
    end

    def serve!
      # Any table that does not return SQL is considered deprecated and we should fully skip it
      if collection.empty? && include_insert
        DataTaster.safe_execute("DROP TABLE IF EXISTS #{table_name}")
      else
        criticize_sample do
          ensure_empty_table
          process_select(collection[:select])
        end

        DataTaster::Sanitizer.new(table_name, collection[:sanitize]).clean!
      end
    end

  private

    attr_reader :table_name, :include_insert, :collection

    def criticize_sample(&block)
      DataTaster.critic.criticize_sample(table_name, &block)
    end

    def ensure_empty_table
      DataTaster.safe_execute("TRUNCATE TABLE #{working_db}.#{table_name}")
    end

    def process_select(sql)
      DataTaster.safe_execute(sql)
    rescue => e
      e.message << " executing SQL statement for #{table_name}: #{sql}"
      raise e
    end

    def working_db
      @working_db ||= DataTaster.config.working_client.query_options[:database]
    end
  end
end
