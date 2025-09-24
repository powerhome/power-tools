# frozen_string_literal: true

module TwoPercent
  class BulkProcessor
    def initialize(operations)
      @operations = operations
    end

    def dispatch(event_handler = EventHandler)
      @operations.each do |operation|
        resource, id = parse_path(operation[:path])
        attrs = { resource: resource, id: id, params: operation[:data] }.compact
        event_handler.dispatch(operation[:method], **attrs)
      end
    end

  private

    def parse_path(path)
      _, resource_type, id = path.split("/")

      [resource_type, id]
    end
  end
end
