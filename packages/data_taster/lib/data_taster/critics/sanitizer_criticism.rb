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

        log_horizontal_rule
        log_info("#{table_name} - sanitized #{selections.count} columns in #{duration} seconds")
        log_horizontal_rule
      end
    end
  end
end
