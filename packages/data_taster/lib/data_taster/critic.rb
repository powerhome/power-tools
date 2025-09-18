# frozen_string_literal: true

require "data_taster/critics/sanitizer_criticism"
require "data_taster/critics/sample_criticism"

module DataTaster
  # Tracks the time, row count, and total size by table
  class Critic
    include DataTaster::Critics::SanitizerCriticism
    include DataTaster::Critics::SampleCriticism

    attr_reader :reviews, :sanitization_reviews, :sample_reviews

    def initialize
      @reviews = []
      @sanitization_reviews = []
    end

    def criticize_dump(&block)
      bm, val = measure_block(&block)

      log_horizontal_rule
      log_info("Dump completed in #{bm.real.round(4)} seconds")

      report_exceptional_samples
      report_exceptional_sanitizations

      val
    end

    def criticize_sample(table_name, &block)
      log_horizontal_rule
      bm, val = measure_block(&block)

      review = record_sample_review(table_name, bm)

      publish_sample_review(review)
      log_horizontal_rule

      val
    end

    def criticize_sanitization(table_name, selections, &block)
      bm, val = measure_block(&block)

      review = record_sanitization_review(table_name, selections, bm)

      log_horizontal_rule
      publish_sanitization_review(review)

      val
    end

  private

    # Returns both the benchmark and the value of the block measured
    def measure_block
      val = nil
      bm = Benchmark.measure do
        val = yield
      end

      [bm, val]
    end

    def log_horizontal_rule
      log_info("--------------------------------")
    end

    def log_info(message)
      DataTaster.logger.info(message)
    end
  end
end
