# frozen_string_literal: true

module DataTaster
  # Tracks the time, row count, and total size by table
  class Critic
    def initialize
      @reviews = {}
    end

    def track_dump(&block)
      bm = Benchmark.measure(&block)

      log_info("Dump completed in #{bm.real} seconds")

      @reviews.each do |table_name, review|
        log_info("Table #{table_name} completed in #{review[:time]} seconds")
      end

      report_slowest_table
    end

    def track_table(table_name, &block)
      bm = Benchmark.measure(&block)

      @reviews[table_name] = {
        time: bm.real,
      }
    end

  private

    def report_slowest_table
      log_info("Slowest tables:")

      @reviews.sort_by { |_, review| review[:time] }.last(5).each do |table_name, review|
        log_info("Table #{table_name} completed in #{review[:time]} seconds")
      end
    end

    def log_info(message)
      DataTaster.logger.info(message)
    end
  end
end
