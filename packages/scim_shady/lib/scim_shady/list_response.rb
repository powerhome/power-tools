# frozen_string_literal: true

module ScimShady
  class ListResponse
    include Enumerable

    attr_reader :response, :model

    def initialize(response, model)
      @response = response
      @model = model
    end

    def each(&block)
      resources.each(&block)
    end

    def has_more_pages?
      start_index + per_page <= total_results
    end

    def start_index
      response.fetch("startIndex", 1)
    end

    def per_page
      response["itemsPerPage"].to_i
    end

    def total_results
      response["totalResults"].to_i
    end

    def next_index
      start_index + per_page
    end

    private

    def resources
      @resources ||= response.fetch("Resources", []).map do |item|
        model.new(item)
      end
    end
  end
end
