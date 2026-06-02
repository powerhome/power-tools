# frozen_string_literal: true

module DataTaster
  class ExportContext
    def initialize(table_name, sanitize, insert_table_name: nil)
      @table_name = table_name
      @insert_table_name = insert_table_name || self.class.quote_ident(table_name)
      @rules = DataTaster::Sanitizer.new(table_name, sanitize).sanitization_rules
    end

    def self.quote_ident(name)
      "`#{name.to_s.gsub('`', '``')}`"
    end

    attr_reader :insert_table_name

    def format_row_tuple(columns, row, client)
      frags = columns.map do |col|
        col_key = col.to_s
        if @rules.key?(col_key) # the colunm has a sanitization rule
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
