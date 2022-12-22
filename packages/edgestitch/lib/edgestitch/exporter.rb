# frozen_string_literal: true

module Edgestitch
  # @private
  #
  # This class is responsible for exporting an engine's owned tables and
  # migrations to a SQL file.
  #
  class Exporter
    # Exports an engine using a dump helper (@see Edgestitch::Mysql::Dump)
    #
    # @param engine [Class<Rails::Engine>] the engine to export
    # @param dump [<#export_tables,#export_migrations>] the dump helper
    #
    def self.export(engine, dump)
      new(engine).export(dump)
    end

    attr_reader :engine

    def initialize(engine)
      @engine = engine
      @database_directory_path = engine.root.join("db")
      @extra_tables_path = @database_directory_path.join("extra_tables")
      @structure_file_path = @database_directory_path.join("structure-self.sql")
    end

    def export(dump, to: @structure_file_path)
      StringIO.open do |buffer|
        buffer.puts dump.export_tables(tables)
        buffer.puts
        buffer.puts dump.export_migrations(migrations)
        File.write to, "#{buffer.string.strip}\n"
      end
    end

    def migrations
      @migrations ||= begin
        migrations_glob = @database_directory_path.join("{migrate,migrate.archive}/*.rb")
        Dir[migrations_glob]
          .map { |filename| File.basename(filename).to_i }
          .sort
      end
    end

    def tables
      component_tables + extra_tables
    end

  private

    def extra_tables
      @extra_tables ||= @extra_tables_path.exist? ? @extra_tables_path.readlines.map(&:strip) : []
    end

    def component_tables
      @component_tables ||= models.each_with_object(Set.new) do |model, tables|
        tables << model.table_name if model.table_exists?
      end.sort
    end

    def models
      @models ||= application_record&.descendants || []
    end

    def application_record
      @application_record ||= engine.railtie_namespace&.const_get(:ApplicationRecord, false)
    rescue LoadError, NameError
      nil
    end
  end
end
