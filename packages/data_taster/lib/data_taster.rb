# frozen_string_literal: true

require "logger"

module DataTaster
  autoload :Collection, "data_taster/collection"
  autoload :Confection, "data_taster/confection"
  autoload :DatabaseOutput, "data_taster/adapters/database_output"
  autoload :Detergent, "data_taster/detergent"
  autoload :ExportContext, "data_taster/export_context"
  autoload :FileOutput, "data_taster/adapters/file_output"
  autoload :Helper, "data_taster/helper"
  autoload :MysqlSource, "data_taster/adapters/mysql_source"
  autoload :Output, "data_taster/adapters/output"
  autoload :SanitizerExporter, "data_taster/sanitizer_exporter"
  autoload :Sanitizer, "data_taster/sanitizer"
  autoload :SqlLiteral, "data_taster/sql_literal"

  SKIP_CODE = "skip_processing"

  class << self
    attr_accessor :config
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.reset!
    # TODO: Turn this into objects
    self.config = nil
    @confection = nil
  end

  def self.setup(source:, output:, months: nil, list: nil)
    self.config = Config.new(
      source,
      output,
      months,
      Array.wrap(list || default_list)
    )
  end

  def self.confection
    @confection ||= DataTaster::Confection.new.assemble
  end

  def self.sample!
    config.output.sample!
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
