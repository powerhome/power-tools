# frozen_string_literal: true

module DataTaster
  class FileOutput < Output
    attr_reader :path, :target_database

    def initialize(path:, target_database:, execute: true)
      super()
      @path = path
      @target_database = target_database
      @execute = execute
    end

    def executes?
      @execute
    end

    def file_export?
      true
    end

    def begin_export!(source:) # rubocop:disable Lint/UnusedMethodArgument
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
