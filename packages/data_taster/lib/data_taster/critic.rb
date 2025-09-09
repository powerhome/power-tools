# frozen_string_literal: true

module DataTaster
  # Tracks the time, row count, and total size by table
  class Critic
    attr_reader :reviews

    def initialize
      @reviews = []
    end

    def criticize_dump(&block)
      bm = Benchmark.measure(&block)

      log_info("Dump completed in #{bm.real.round(4)} seconds")

      report_exceptional_tables
    end

    def criticize_sample(table_name, &block)
      bm = Benchmark.measure(&block)

      review = {
        table_name: table_name,
        time: bm.real.round(4),
        rows:  DataTaster.safe_execute("SELECT COUNT(*) FROM #{table_name}").first["COUNT(*)"],
        size: DataTaster.safe_execute(table_size_sql(table_name)).first["size_mb"],
      }

      reviews << review

      log_horizontal_rule
      publish(review)
      log_horizontal_rule
    end

  private

    def table_size_sql(table_name)
      <<-SQL.squish
        SELECT ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as size_mb
        FROM information_schema.tables WHERE table_name = '#{table_name}'
      SQL
    end

    def publish(review)
      size = review[:size]
      rows = review[:rows]
      duration = review[:time]

      log_info("Table #{review[:table_name]} completed in #{duration} seconds," \
               " dumped #{rows} #{"row".pluralize(rows)} and #{size} MB of data")
    end

    def log_horizontal_rule
      log_info("--------------------------------")
    end

    def report_exceptional_tables
      log_horizontal_rule
      report_slowest_tables
      report_largest_tables_by_size
      report_largest_tables_by_rows
    end

    def report_slowest_tables
      log_info("Slowest tables:")

      log_horizontal_rule
      @reviews.sort_by { |review| -(review[:time] || 0) }.first(5).each { |review| publish(review) }
      log_horizontal_rule
    end

    def report_largest_tables_by_size
      log_info("Largest tables by size:")

      log_horizontal_rule
      @reviews.sort_by { |review| -(review[:size] || 0) }.first(5).each { |review| publish(review) }
      log_horizontal_rule
    end

    def report_largest_tables_by_rows
      log_info("Largest tables by rows:")

      log_horizontal_rule
      @reviews.sort_by { |review| -(review[:rows] || 0) }.first(5).each { |review| publish(review) }
      log_horizontal_rule
    end

    def log_info(message)
      DataTaster.logger.info(message)
    end
  end
end
