# frozen_string_literal: true

module TwoPercent
  class BulkController < ApplicationController
    def _dispatch
      log_bulk_operation("start")
      processor.dispatch
      log_bulk_operation("complete")
    end

  private

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
        service: "two_percent",
      }

      Rails.logger.info(log_data.to_json)
    end
  end
end
