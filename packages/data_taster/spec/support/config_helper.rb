# frozen_string_literal: true

require "spec_helper"

module ConfigHelper
  def configure_data_taster(**options)
    DataTaster.reset!
    DataTaster.setup(**data_taster_setup_options(options))
  end

  def default_config_list
    [File.join(__dir__, "..", "fixtures", "data_taster_export_tables.yml")]
  end

private

  def data_taster_setup_options(options)
    {
      source: mysql_source(options.fetch(:source_client) { source_db_client }),
      output: data_taster_output(options),
      months: options[:months],
      list: options[:list] || default_config_list,
    }
  end

  def mysql_source(client)
    DataTaster::MysqlSource.new(client: client)
  end

  def data_taster_output(options)
    if options[:path]
      DataTaster::FileOutput.new(
        path: options[:path],
        target_database: options.fetch(:target_database) { dump_db_name }
      )
    else
      DataTaster::DatabaseOutput.new(client: options.fetch(:output_client) { dump_db_client })
    end
  end
end

RSpec.configure do |config|
  config.include ConfigHelper
end
