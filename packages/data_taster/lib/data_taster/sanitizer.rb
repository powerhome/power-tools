# frozen_string_literal: true

module DataTaster
  class Sanitizer
    BATCH_SIZE = 100

    # Ensures the given tables are cleaned of information deemed sensitive
    def initialize(table_name, custom_selections)
      @table_name = table_name
      @custom_selections = custom_selections || {}
    end

    def clean!
      return if skippable_table?

      # custom selections should ALWAYS override defaults
      default_selections.merge(custom_selections).filter_map do |column_name, sanitized_value|
        sql = DataTaster::Detergent.new(
          table_name, column_name, sanitized_value
        ).deliver

        process(sql)
      end
    end

    def sanitization_rules
      return {} if skippable_table?

      default_selections.merge(custom_selections).each_with_object({}) do |(column_name, sanitized_value), memo|
        next if sanitized_value == DataTaster::SKIP_CODE

        memo[column_name.to_s] = sanitized_value
      end
    end

    def export_sanitized_rows(collection, insert_table_name:, &write_insert)
      @export_context = ExportContext.new(table_name, custom_selections, insert_table_name: insert_table_name)
      query_result = export_source.query(collection.export_select_sql)

      columns = query_result.fields
      return if columns.empty?

      process_export_in_batches(columns, query_result, &write_insert)
    end

  private

    attr_reader :table_name, :custom_selections

    def process_export_in_batches(columns, query_result, &write_insert)
      batch = []
      query_result.each do |row|
        batch << row
        if batch.size >= BATCH_SIZE
          write_export_batch(columns, batch, &write_insert)
          batch.clear
        end
      end
      write_export_batch(columns, batch, &write_insert) if batch.any?
    end

    def write_export_batch(columns, rows)
      return if rows.empty?

      client = export_source.source_client
      col_list = columns.map { |c| ExportContext.quote_ident(c) }.join(", ")
      tuples = rows.map { |row| @export_context.format_row_tuple(columns, row, client) }
      header = "INSERT INTO #{@export_context.insert_table_name} (#{col_list}) VALUES"
      values = tuples.join(",\n")

      yield(header, values)
    end

    def export_source
      DataTaster.config.source
    end

    def process(sql)
      return if sql == DataTaster::SKIP_CODE
      return sql unless executes_sanitizer?

      output.write_statement(sql)
      sql
    rescue => e
      raise e, e.message + context_warning
    end

    def context_warning
      <<~WARNING

        *****

        DATA TASTER WARNING: Many columns are sanitized by default for safety. Please check DataTaster documentation for more details.

        *****

      WARNING
    end

    def output
      DataTaster.config.output
    end

    def executes_sanitizer?
      output.export_mode == :database
    end

    def skippable_table?
      DataTaster.confection[table_name].blank? ||
        DataTaster.confection[table_name] == DataTaster::SKIP_CODE
    end

    def default_selections
      table_columns.each_with_object({}) do |table_col, selections|
        sanitized_value = defaults.select do |default_col|
          table_col.match(default_col)
        end&.first&.last

        next unless sanitized_value

        selections[table_col] = sanitized_value
      end
    end

    def table_columns
      @table_columns ||= ActiveRecord::Base
                         .connection
                         .schema_cache
                         .columns(table_name.to_s)
                         .map(&:name)
    end

    def defaults # rubocop:disable Metrics/MethodLength
      {
        # `encrypted` should be removed if it is not custom-sanitized
        /encrypted/ => "",
        /#{exceptions}.*(ssn|passport|license)/ => "111111111",
        /#{exceptions}.*(dob|birth)/ => Date.current - 29.years,
        /#{exceptions}.*(note|body)/ => "Redacted for privacy",
        /#{exceptions}.*(compensation|income)/ => 999_999,
        /#{exceptions(extra: ['2'])}.*email.*/ => "CONCAT('#{table_name}_', id, '@nitrophrg.com')",
        /email.*2$/ => "CONCAT('#{table_name}_', id, '_2', '@nitrophrg.com')",
        /#{exceptions(extra: %w[2 email])}.*address.*/ => "CONCAT(id, ' Disneyland Dr')",
        /#{exceptions(extra: ['email'])}.*address.*2/ => "Unit M",
      }.freeze
    end

    def exceptions(extra: [])
      default = %w[_id _at type subject ip mac remote count encrypted voice count]
      all_exceptions = default + extra

      "^(?!.*(?:#{all_exceptions.join('|')}))"
    end
  end
end
