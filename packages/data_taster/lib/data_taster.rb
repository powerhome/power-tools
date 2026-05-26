# frozen_string_literal: true

require "logger"

module DataTaster
  autoload :Collection, "data_taster/collection"
  autoload :Confection, "data_taster/confection"
  autoload :DatabaseOutput, "data_taster/adapters/database_output"
  autoload :Detergent, "data_taster/detergent"
  autoload :DetergentRowInterpolator, "data_taster/detergent_row_interpolator"
  autoload :Exporter, "data_taster/exporter"
  autoload :FileOutput, "data_taster/adapters/file_output"
  autoload :Helper, "data_taster/helper"
  autoload :MysqlSource, "data_taster/adapters/mysql_source"
  autoload :Output, "data_taster/adapters/output"
  autoload :Sanitizer, "data_taster/sanitizer"
  autoload :SqlLiteral, "data_taster/sql_literal"

  SKIP_CODE = "skip_processing"

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.reset!
    @config = nil
    @confection = nil
  end

  def self.config(source:, output:, months: nil, list: default_list)
    @config = Config.new(
      source,
      output,
      months,
      Array.wrap(list)
    )
  end

  def self.confection
    @confection ||= DataTaster::Confection.new.assemble
  end

  def self.sample!
    Exporter.new.serve!
  end

  def self.target_database
    config.output.target_database
  end

  def self.safe_execute(sql, client = nil)
    client ||= config.output.client if config.output.respond_to?(:client)

    foreign_key_check = client.query("SELECT @@FOREIGN_KEY_CHECKS").first["@@FOREIGN_KEY_CHECKS"]

    begin
      client.query("SET FOREIGN_KEY_CHECKS=0")
      client.query(sql)
    ensure
      client.query("SET FOREIGN_KEY_CHECKS=#{foreign_key_check};")
    end
  end

  def self.default_list
    if defined?(Rails) && Rails.respond_to?(:root)
      Rails.root.glob("**/data_taster_export_tables.yml")
    else
      []
    end
  end

  Config = Struct.new(:source, :output, :months, :list)
end
