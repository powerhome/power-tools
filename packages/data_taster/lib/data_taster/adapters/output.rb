# frozen_string_literal: true

module DataTaster
  class Output
    def target_database
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

    def executes?
      true
    end

    def file_export?
      false
    end

    def database_export?
      false
    end
  end
end
