# frozen_string_literal: true

require "logger"

module DataTaster
  autoload :Collection, "data_taster/collection"
  autoload :Confection, "data_taster/confection"
  autoload :Detergent, "data_taster/detergent"
  autoload :Helper, "data_taster/helper"
  autoload :Sample, "data_taster/sample"
  autoload :Sanitizer, "data_taster/sanitizer"
  autoload :Critic, "data_taster/critic"

  SKIP_CODE = "skip_processing"

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.critic
    @critic ||= Critic.new
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
    critic.track_dump do
      DataTaster
        .config
        .source_client
        .query("SHOW tables").collect { |t| t[t.keys.first] }
        .each do |table_name|
          DataTaster::Sample.new(table_name).serve!
        end
    end
  end

  def self.safe_execute(sql, client = DataTaster.config.working_client)
    foreign_key_check = client.query("SELECT @@FOREIGN_KEY_CHECKS").first["@@FOREIGN_KEY_CHECKS"]

    begin
      client.query("SET FOREIGN_KEY_CHECKS=0")
      client.query(sql)
    ensure
      client.query("SET FOREIGN_KEY_CHECKS=#{foreign_key_check};")
    end
  end

  Config = Struct.new(:months, :list, :source_client, :working_client, :include_insert)
end
