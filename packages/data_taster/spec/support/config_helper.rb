# frozen_string_literal: true

require "spec_helper"

module ConfigHelper
  def configure_data_taster(source_client: source_db_client, output_client: dump_db_client,
                            target_database: dump_db_name)
    source = DataTaster::MysqlSource.new(client: source_client)
    output = if path
               DataTaster::FileOutput.new(path: path, target_database: target_database, execute: execute)
             else
               DataTaster::DatabaseOutput.new(client: output_client, execute: execute)
             end

    DataTaster.reset!
    DataTaster.setup(source: source, output: output, list: default_config_list)
  end

  def default_config_list
    [File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml")]
  end
end

RSpec.configure do |config|
  config.include ConfigHelper
end
