# frozen_string_literal: true

module TwoPercent
  class BulkController < ApplicationController
    def _dispatch = processor.dispatch

  private

    def processor
      @processor ||= TwoPercent::BulkProcessor.new(operations)
    end

    def operations
      params.require(:Operations).map(&:permit!).map(&:to_h)
    end
  end
end
