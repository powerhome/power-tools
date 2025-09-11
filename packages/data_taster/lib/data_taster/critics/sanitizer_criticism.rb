# frozen_string_literal: true

module DataTaster
  module Critics
    module SanitizerCriticism
    private

      def record_sanitization_review(table_name, selections, benchmark)
        review = {
          table_name: table_name,
          selections: selections,
          duration: benchmark.real.round(4),
        }

        sanitization_reviews << review

        review
      end

      def publish_sanitization_review(review)
        selections = review[:selections]
        duration = review[:duration]
        table_name = review[:table_name]

        log_info("#{table_name} - sanitized #{selections&.count || 0} columns in #{duration} seconds")
      end

      def report_exceptional_sanitizations
        report_slowest_sanitizations
        report_most_columns_sanitized
      end

      def report_slowest_sanitizations
        log_info("Slowest sanitizations:")

        log_horizontal_rule
        sanitization_reviews.sort_by { |review| -(review[:duration] || 0) }.first(5).each do |review|
          publish_sanitization_review(review)
        end
        log_horizontal_rule
      end

      def report_most_columns_sanitized
        log_info("Most columns sanitized:")

        log_horizontal_rule
        sanitization_reviews.sort_by { |review| -(review[:selections]&.count || 0) }.first(5).each do |review|
          publish_sanitization_review(review)
        end
        log_horizontal_rule
      end
    end
  end
end
