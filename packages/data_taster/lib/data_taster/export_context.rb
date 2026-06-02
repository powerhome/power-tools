# frozen_string_literal: true

module DataTaster
  class ExportContext
    def self.quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end

    def initialize(table_name, sanitize)
      @table_name = table_name
      @safe_table_name = self.class.quote_ident(table_name)
      @rules = DataTaster::Sanitizer.new(table_name, sanitize).sanitization_rules
    end

    attr_reader :safe_table_name

    def format_row_tuple(columns, row, client)
      frags = columns.map do |col|
        col_key = col.to_s
        if @rules.key?(col_key)
          DataTaster::Detergent.new(@table_name, col_key, @rules[col_key])
            .insert_value_expression(row, client)
        else
          DataTaster::SqlLiteral.format(client, row[col])
        end
      end
      "(#{frags.join(', ')})"
    end
  end
end
