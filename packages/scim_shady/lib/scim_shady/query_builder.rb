# frozen_string_literal: true

module ScimShady
  class QueryBuilder
    include Enumerable

    attr_reader :model, :options
    delegate_missing_to :response

    def initialize(model:, attributes: nil, **options)
      @model = model
      @options = options
      @options[:attributes] = Array(attributes).join(",") if attributes
    end

    def attributes(*attrs)
      build(attributes: attrs)
    end

    def filter(filter)
      build(filter: [options[:filter], filter].compact.join(" AND "))
    end

    def pluck(*attrs)
      attr_names = attrs.map(&:to_s)
      attributes(*attrs).map do |obj|
        obj.attributes.values_at(*attr_names)
      end
    end

    def all
      to_enum(:each_all_pages)
    end

    def next_page
      return unless has_more_pages?

      @next_page ||= build(startIndex: next_index)
    end

    private

    def build(**kwargs)
      QueryBuilder.new(model: @model, **@options, **kwargs)
    end

    def each_all_pages(&block)
      each(&block)
      next_page&.send(:each_all_pages, &block)
    end

    def response
      @response ||= ScimShady.client.get(path: @model.resource_path, query: @options, list: @model)
    end
  end
end
