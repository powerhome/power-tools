# frozen_string_literal: true

module DataTaster
  # helper methods made to make data_taster_export_tables.yml
  # files more user-friendly
  class Flavors
    include DataTaster::Helper

    def current_date
      @current_date ||= Date.current
    end

    def date
      @date ||= if DataTaster.config.months
                  (current_date - DataTaster.config.months.to_i.months).beginning_of_day.to_s(:db)
                else
                  (current_date - 1.week).beginning_of_day.to_s(:db)
                end
    end

    # skips dumping both schema and data
    def deprecated_table
      DataTaster::SKIP_CODE
    end

    def skip_sanitization
      DataTaster::SKIP_CODE
    end

    def encrypt(klass, column, value = nil)
      value_to_encrypt = value || default_value_for(column)

      klass_instance = klass.new

      if klass_instance.respond_to?(:attr_encrypted_encrypt)
        klass_instance.attr_encrypted_encrypt(column, value_to_encrypt)
      elsif klass_instance.respond_to?(:encrypt)
        klass_instance.encrypt(column, value_to_encrypt)
      else
        error_message = [
          "DataTaster only supports encryption if your model is configured with attr_encrypted.",
          "Please visit https://github.com/attr-encrypted/attr_encrypted for more details on setup."
        ].join(" ")

        raise error_message
      end
    end

    def default_value_for(column)
      case column
      when /date_of_birth/, /dob/
        (Date.current - 25.years).strftime("%m/%d/%Y")
      when /ssn/, /license/
        "111111111"
      when /compensation/
        1
      else
        "1"
      end
    end

    def full_table_dump
      "1 = 1"
    end

    def recent_table_updates
      "created_at >= '#{date}' OR updated_at >= '#{date}'"
    end

    def recent_ids(table_name, col_name)
      <<~SQL.squish
        (SELECT DISTINCT(#{col_name})
        FROM #{source_db}.#{table_name}
        WHERE
        created_at >= '#{date}'
        OR
        updated_at >= '#{date}')
      SQL
    end

    def source_db
      @source_db ||= db_config["database"]
    end
  end
end
