# frozen_string_literal: true

module DataTaster
  class Output
    def initialize(**options)
      options.each { |key, value| instance_variable_set(:"@#{key}", value) }
    end

    def sample!
      raise NotImplementedError
    end

    def default_data
      raise NotImplementedError
    end

    def run_sanitization?
      raise NotImplementedError
    end

    def target_database
      raise NotImplementedError
    end

    def qualified_table_name(table_name)
      raise NotImplementedError
    end

    def write_statement(_sql)
      raise NotImplementedError
    end

    def write_raw(_line)
      raise NotImplementedError
    end
  end
end
