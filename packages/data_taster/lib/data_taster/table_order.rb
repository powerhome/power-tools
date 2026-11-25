# frozen_string_literal: true

require "tsort"

module DataTaster
  # Orders tables so each one comes after the tables its select: clause names without a database. On a server-side
  # copy those names resolve against the target, so the tables they name must already hold their sampled rows.
  # Tables in a cycle, and tables that name no other, keep the order they were given in.
  class TableOrder
    include TSort

    def initialize(table_names)
      @table_names = table_names
      @positions = table_names.each_with_index.to_h
    end

    def to_a
      each_strongly_connected_component.flat_map { |tables| tables.sort_by { |table| @positions[table] } }
    end

  private

    def tsort_each_node(&block)
      @table_names.each(&block)
    end

    def tsort_each_child(table_name, &block)
      DataTaster::Collection.new(table_name).unqualified_names
                            .select { |name| name != table_name && @positions.key?(name) }
                            .sort_by { |name| @positions[name] }
                            .each(&block)
    end
  end
end
