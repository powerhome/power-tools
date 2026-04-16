# frozen_string_literal: true

module TwoPercent
  class BulkController < ApplicationController
    before_action :extract_correlation_id

    def _dispatch
      log_bulk_operation("start")
      processor.dispatch
      log_bulk_operation("complete")
    end

  private

    def extract_correlation_id
      @correlation_id = request.headers["X-Correlation-Id"] || SecureRandom.uuid
    end

    def processor
      @processor ||= TwoPercent::BulkProcessor.new(operations, correlation_id: @correlation_id)
    end

    def operations
      params.require(:Operations).map { _1.permit(:method, :path, :bulkId, data: {}).to_h }
    end

    def log_bulk_operation(stage)
      log_data = {
        correlation_id: @correlation_id,
        operation: "bulk",
        operation_count: operations.size,
        stage: stage,
        service: "two_percent"
      }

      Rails.logger.info(log_data.to_json) if defined?(Rails)
    end
  end
end
