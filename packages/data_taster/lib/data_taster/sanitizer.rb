# frozen_string_literal: true

module DataTaster
  class Sanitizer
    # Ensures the given tables are cleaned of
    # information deemed sensitive
    def initialize(table_name, custom_selections)
      @table_name = table_name
      @custom_selections = custom_selections || {}
      @include_insert = DataTaster.config.include_insert
    end

    def clean!
      return if skippable_table?

      selections = default_selections.merge(custom_selections)
      # custom selections should ALWAYS override defaults
      criticize_sanitization(selections) do
        selections.filter_map do |column_name, sanitized_value|
          sql = DataTaster::Detergent.new(
            table_name, column_name, sanitized_value
          ).deliver

          process(sql)
        end
      end
    end

  private

    attr_reader :table_name, :custom_selections, :include_insert

    def criticize_sanitization(selections, &block)
      DataTaster.critic.criticize_sanitization(table_name, selections, &block)
    end

    def process(sql)
      return if sql == DataTaster::SKIP_CODE
      return sql unless include_insert

      DataTaster.safe_execute(sql)
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
