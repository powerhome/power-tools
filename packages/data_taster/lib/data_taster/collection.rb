# frozen_string_literal: true

module DataTaster
  # Ingests the processed yml file and returns either
  # an empty hash (for cases that are skippable)
  # or a hash that contains:
  # select:
  # (whatever is configured to go in the SELECT .. WHERE clause)
  # sanitize:
  # the columns and values that need custom sanitization
  class Collection
    def initialize(table_name)
      @table_name = table_name
      @ingredients = DataTaster.confection[table_name]
      @include_insert = DataTaster.config.include_insert
    end

    def assemble
      DataTaster.logger.info("#{table_name}...")

      if skippable?
        DataTaster.logger.info("configured to skip both schema and data")
        {}
      else
        { select: selection, sanitize: sanitization }
      end
    end

  private

    attr_reader :table_name, :ingredients, :include_insert

    def skippable?
      table_name.downcase.match(/^_/) ||
        ingredients == DataTaster::SKIP_CODE
    end

    def selection
      insert = include_insert ? "INSERT INTO #{working_db}.#{table_name}" : ""

      sql = <<-SQL.squish
        #{insert}
        SELECT * FROM #{source_db}.#{table_name}
        WHERE #{where_clause}
      SQL

      DataTaster.logger.info(sql)
      sql
    end

    # The yml file allows you to define either a simple clause
    # or some more fine-grained sanitization. If neither is
    # defined, we pass a clause that selects nothing.
    def where_clause
      clause = ingredients.is_a?(Hash) ? ingredients["select"] : ingredients

      clause || "1 = 0"
    end

    def sanitization
      return unless ingredients.is_a?(Hash)

      ingredients["sanitize"]
    end

    def source_db
      @source_db ||= DataTaster.config.source_client.query_options[:database]
    end

    def working_db
      @working_db ||= DataTaster.config.working_client.query_options[:database]
    end
  end
end
