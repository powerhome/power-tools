# frozen_string_literal: true

module DataTaster
  class FileOutput < Output
    attr_reader :path, :target_database

    def initialize(path:, target_database:)
      super()
      @path = path
      @target_database = target_database
    end

    def export_mode
      :file
    end

    def qualified_table_name(table_name)
      "`#{table_name.to_s.gsub('`', '``')}`"
    end

    def begin_export!(**)
      DataTaster.logger.info("Writing SQL file to #{path}")
      @io = File.open(path, "w")
      @io.puts "SET FOREIGN_KEY_CHECKS=0;"
    end

    def write_statement(sql)
      @io.puts "#{sql};"
    end

    def write_raw(line)
      @io.puts line
    end

    def finish_export!
      @io.puts "SET FOREIGN_KEY_CHECKS=1;"
      @io.close
    end
  end
end
