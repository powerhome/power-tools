# frozen_string_literal: true

module DataTaster
  class Output
    def target_database
      raise NotImplementedError
    end

    def export_mode
      raise NotImplementedError
    end

    def table_names(source)
      raise NotImplementedError
    end

    def qualified_table_name(table_name)
      raise NotImplementedError
    end

    def begin_export!(source:); end

    def write_statement(_sql)
      raise NotImplementedError
    end

    def write_raw(_line)
      raise NotImplementedError
    end

    def finish_export!; end
  end
end
