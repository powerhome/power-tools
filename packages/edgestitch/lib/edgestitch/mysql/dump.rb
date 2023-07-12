# frozen_string_literal: true

require "open3"

require_relative "structure_constraint_order_munger"

module Edgestitch
  module Mysql
    # @private
    #
    # Wrapper for the mysqldump tool to dump specific tables and migration data
    #
    class Dump
      # Sanitizes a DDL code with some opinionated preferences:
      # * Constraints starting with `_fk` will start with `fk`
      # * Clear empty lines (with empty spaces even)
      # * Reorder constraints (@see Edgestitch::Mysql::StructureConstraintOrderMunger)
      #
      # @param sql [String] the DDL code to sanitize
      # @return String the same DDL sanitized
      def self.sanitize_sql(sql)
        comment_instructions_regex = %r{^/\*![0-9]{5}\s+[^;]+;\s*$}

        cleanups = sql.gsub(/\s+AUTO_INCREMENT=\d+/, "")
                      .gsub(/CONSTRAINT `_+fk_/, "CONSTRAINT `fk_")
                      .gsub(comment_instructions_regex, "")
                      .gsub(/\n\s*\n\s*\n/, "\n\n")
                      .strip
        ::Edgestitch::Mysql::StructureConstraintOrderMunger.munge(cleanups)
      end

      #
      # @param config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] rails database configuration
      def initialize(config)
        hash = config.respond_to?(:configuration_hash) ? config.configuration_hash : config.config
        @database = hash["database"] || hash[:database]
        @config = {
          "-h" => hash["host"] || hash[:host],
          "-u" => hash["username"] || hash[:username],
          "-p" => hash["password"] || hash[:password],
          "--port=" => hash["port"] || hash[:port],
        }
      end

      # Exports DDL for the given tables in a mysql compatible way
      #
      # @param tables [Array<String>] table names
      # @return String the DDL for the given tables
      def export_tables(tables)
        return if tables.empty?

        self.class.sanitize_sql(
          execute("--compact", "--skip-lock-tables", "--no-data", "--set-gtid-purged=OFF",
                  "--column-statistics=0", *tables)
        )
      end

      # Exports INSERT statements for the given migration names.
      #
      # The INSERT statements are in groups of 50 migrations per multi-insert statement.
      #
      # Notice: this does not export the creation of the schema_migrations table.
      #
      # @param migrations [Array<Integer,String>] migration ids/timestamps
      # @return String the INSERT statements.
      def export_migrations(migrations)
        migrations.in_groups_of(50, false).map do |versions|
          execute(
            "--compact", "--skip-lock-tables", "--set-gtid-purged=OFF",
            "--no-create-info", "--column-statistics=0",
            "schema_migrations",
            "-w", "version IN (#{versions.join(',')})"
          )
        end.join.gsub("VALUES ", "VALUES\n").gsub(",", ",\n")
      end

    private

      def execute(*args)
        stdout, stderr, status = Open3.capture3("mysqldump", *connection_args, @database, *args)
        raise stderr unless status.success?

        stdout
      end

      def connection_args
        @config.compact.map do |arg, value|
          "#{arg}#{value}"
        end
      end
    end
  end
end
