# frozen_string_literal: true

module DataTaster
  # Returns SQL for given data, based on types. Used for sanitizing inputs.
  class Detergent
    SANITIZE_FUNCTIONS = [
      /CONCAT/,
      /DATE/,
      /DAY/,
      /FORMAT/,
      /LOWER/,
      /REPLACE/,
      /TRIM/,
      /UCASE/,
      /UPPER/,
    ].freeze

    def initialize(table_name, column_name, given_value)
      @table_name = table_name
      @column_name = column_name
      @value = parse_value(given_value)
    end

    def deliver
      return value if value == DataTaster::SKIP_CODE

      sql = sql_for(value)

      DataTaster.logger.info("--> #{sql}")
      sql
    end

  private

    attr_reader :table_name, :column_name, :value

    def parse_value(given_value)
      # yml files can't hold custom-set dates, they have to be converted to strings
      return given_value unless given_value.is_a?(String) && given_value.match?(/\d{4}-\d{2}-\d{2}/)

      Date.parse(given_value)
    end

    def sql_for(value)
      if value.is_a?(Date)
        sql_for_date_value
      elsif value.is_a?(Numeric) || sanitize_function?
        sql_for_uncast_value
      elsif value.blank?
        sql_for_nil_value
      else
        sql_for_cast_value
      end
    end

    def sanitize_function?
      SANITIZE_FUNCTIONS.any? { |fun| value.to_s.match(fun) }
    end

    def sql_for_uncast_value
      <<-SQL.squish
        UPDATE #{working_db}.#{table_name}
        SET #{column_name} = #{value}
        WHERE #{column_name} IS NOT NULL
        AND #{column_name} <> #{value}
      SQL
    end

    def sql_for_date_value
      <<-SQL.squish
        UPDATE #{working_db}.#{table_name}
        SET #{column_name} = '#{value}'
        WHERE #{column_name} IS NOT NULL
      SQL
    end

    def sql_for_nil_value
      <<-SQL.squish
        UPDATE #{working_db}.#{table_name}
        SET #{column_name} = NULL
        WHERE #{column_name} IS NOT NULL
      SQL
    end

    def sql_for_cast_value
      <<-SQL.squish
        UPDATE #{working_db}.#{table_name}
        SET #{column_name} = '#{value}'
        WHERE #{column_name} IS NOT NULL
        AND #{column_name} <> ''
      SQL
    end

    def working_db
      DataTaster.config.working_client.query_options[:database]
    end
  end
end
