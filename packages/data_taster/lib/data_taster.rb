# frozen_string_literal: true

require "logger"

module DataTaster
  autoload :Collection, "data_taster/collection"
  autoload :Confection, "data_taster/confection"
  autoload :Detergent, "data_taster/detergent"
  autoload :Helper, "data_taster/helper"
  autoload :Sample, "data_taster/sample"
  autoload :Sanitizer, "data_taster/sanitizer"

  SKIP_CODE = "skip_processing"

  # TODO: Remove testing logs
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.config(**args)
    @config ||= Config.new(
      args[:months],
      Array.wrap(args[:list] || Rails.root.glob("**/data_taster_export_tables.yml")),
      args[:source_client] || raise(ArgumentError, "DataTaster.config missing source_client"),
      args[:working_client] || raise(ArgumentError, "DataTaster.config missing working_client"),
      args[:include_insert] || false
    )
  end

  def self.confection
    @confection ||= DataTaster::Confection.new.assemble
  end

  def self.sample!
    all_tables_names.each do |table_name|
      DataTaster::Sample.new(table_name).serve!
    end

    logger.info("DataTaster: sample! finished (#{all_tables_names.size} tables)")
  end

  def self.sample_selected_tables!
    selected_tables_names.each do |table_name|
      Rails.logger.info("DataTaster: sampling table: #{table_name}")
      DataTaster::Sample.new(table_name).serve!
    end

    logger.info("DataTaster: sample_configured_tables! finished (#{selected_tables_names.size} tables)")
  end

  def self.sanitize_selected_tables!
    selected_tables_names.each do |table_name|
      log_msg = "DataTaster: sanitizing table: #{table_name}"
      logger.info(log_msg)
      Rails.logger.info(log_msg) if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      collection = DataTaster::Collection.new(table_name).assemble
      next if collection.empty?

      DataTaster::Sanitizer.new(table_name, collection[:sanitize]).clean!
    end

    logger.info("DataTaster: sanitize_configured_tables! finished (#{selected_tables_names.size} tables)")
  end

  def self.safe_execute(sql, client = DataTaster.config.working_client)
    foreign_key_check = client.query("SELECT @@FOREIGN_KEY_CHECKS").first["@@FOREIGN_KEY_CHECKS"]

    begin
      client.query("SET FOREIGN_KEY_CHECKS=0")
      client.query(sql)
      client.affected_rows
    ensure
      client.query("SET FOREIGN_KEY_CHECKS=#{foreign_key_check};")
    end
  end

  def self.all_tables_names
    config.source_client.query("SHOW TABLES").map { |t| t[t.keys.first] }
  end

  def self.selected_tables_names
    DataTaster.confection.keys
  end

  Config = Struct.new(:months, :list, :source_client, :working_client, :include_insert)
end
