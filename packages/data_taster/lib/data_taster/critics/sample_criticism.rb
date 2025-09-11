# frozen_string_literal: true

module DataTaster
  module Critics
    module SampleCriticism
    private

      def record_sample_review(table_name, benchmark)
        review = {
          table_name: table_name,
          duration: benchmark.real.round(4),
          rows: dump_table_rows(table_name),
          size: dump_table_size(table_name),
          source_rows: source_table_rows(table_name),
          source_size: source_table_size(table_name),
        }

        reviews << review

        review
      end

      def publish_sample_review(review)
        table_name = review[:table_name]
        dump_size = review[:size]
        dump_rows = review[:rows]
        source_size = review[:source_size]
        source_rows = review[:source_rows]
        duration = review[:duration]

        log_info("#{table_name} - dumped #{dump_rows} of #{source_rows} #{'row'.pluralize(source_rows)} " \
                 "and #{dump_size} of #{source_size} MB of data in #{duration} seconds,")
      end

      def dump_table_size(table_name)
        DataTaster.safe_execute(table_size_sql(table_name)).first["size_mb"]
      end

      def source_table_size(table_name)
        DataTaster.safe_execute(table_size_sql(table_name), DataTaster.config.source_client).first["size_mb"]
      end

      def dump_table_rows(table_name)
        DataTaster.safe_execute(count_sql(table_name)).first["COUNT(*)"]
      end

      def source_table_rows(table_name)
        DataTaster.safe_execute(count_sql(table_name), DataTaster.config.source_client).first["COUNT(*)"]
      end

      def count_sql(table_name)
        "SELECT COUNT(*) FROM #{table_name}"
      end

      def table_size_sql(table_name)
        <<-SQL.squish
          SELECT ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as size_mb
          FROM information_schema.tables WHERE table_name = '#{table_name}'
        SQL
      end

      def report_exceptional_samples
        log_horizontal_rule
        report_slowest_tables
        report_largest_tables_by_size
        report_largest_tables_by_rows
      end

      def report_slowest_tables
        log_info("Slowest tables:")

        log_horizontal_rule
        @reviews.sort_by { |review| -(review[:time] || 0) }.first(5).each { |review| publish_sample_review(review) }
        log_horizontal_rule
      end

      def report_largest_tables_by_size
        log_info("Largest tables by size:")

        log_horizontal_rule
        @reviews.sort_by { |review| -(review[:size] || 0) }.first(5).each { |review| publish_sample_review(review) }
        log_horizontal_rule
      end

      def report_largest_tables_by_rows
        log_info("Largest tables by rows:")

        log_horizontal_rule
        @reviews.sort_by { |review| -(review[:rows] || 0) }.first(5).each { |review| publish_sample_review(review) }
        log_horizontal_rule
      end
    end
  end
end
