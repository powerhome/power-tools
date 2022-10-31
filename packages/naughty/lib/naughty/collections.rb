# frozen_string_literal: true

module Naughty
  class MappedCollection < Array
    def initialize(builder, records)
      @builder = builder
      @records = records
      self << records.map(&builder.method(:new))
      flatten!
    end
  end

  class PaginatedCollection < MappedCollection
    attr_accessor :total_pages, :current_page, :total_entries

    def initialize(builder, records, pagination = {})
      paginated = records.paginate(pagination)

      @total_pages = paginated.total_pages
      @current_page = paginated.current_page
      @total_entries = paginated.total_entries

      super builder, paginated
    end
  end
end
