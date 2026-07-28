# frozen_string_literal: true

module DataTaster
  class SanitizerExporter
    BATCH_SIZE = 100

    def initialize(table_name, custom_selections, insert_table_name:)
      @table_name = table_name
      @custom_selections = custom_selections
      @insert_table_name = insert_table_name
    end

    def export_sanitized_rows(collection, &write_insert)
      query_result = export_source.query(collection.export_select_sql)

      columns = query_result.fields
      return if columns.empty?

      export_context = build_export_context(columns, query_result)
      process_export_in_batches(export_context, columns, query_result, &write_insert)
    end

  private

    attr_reader :table_name, :custom_selections, :insert_table_name

    def process_export_in_batches(export_context, columns, query_result, &write_insert)
      batch = []
      query_result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(export_context, columns, batch, &write_insert)
          batch.clear
        end
      end
      write_export_batch(export_context, columns, batch, &write_insert) if batch.any?
    end

    def write_export_batch(export_context, columns, rows, &_write_insert)
      return if rows.empty?

      client = export_source.source_client
      col_list = columns.map { |c| ExportContext.quote_ident(c) }.join(", ")
      tuples = rows.map { |row| export_context.format_row_tuple(columns, row, client) }
      header = "INSERT INTO #{export_context.insert_table_name} (#{col_list}) VALUES"
      values = tuples.join(",\n")

      yield(header, values)
    end

    def export_source
      DataTaster.config.source
    end

    def build_export_context(columns, query_result)
      column_types = columns.zip(query_result.field_types).to_h.transform_keys(&:to_s)
      ExportContext.new(
        table_name,
        custom_selections,
        insert_table_name: insert_table_name,
        column_types: column_types
      )
    end
  end
end
