# frozen_string_literal: true

# Helper methods to get database configurations, accounting for changes between rails versions
module DatabaseHelper
  def source_db_config
    { key: "primary", name: "test_source" }
  end

  def dump_db_config
    { key: "test_dump", name: "test_dump" }
  end

  def dump_db_name
    dump_db_config[:name]
  end

  def dump_db_config_key
    dump_db_config[:key]
  end

  def dump_db_client
    @dump_db_client ||= Mysql2::Client.new(test_dump_database_config)
  end

  def source_db_name
    source_db_config[:name]
  end

  def source_db_config_key
    source_db_config[:key]
  end

  def source_db_client
    @source_db_client ||= Mysql2::Client.new(test_source_database_config)
  end

  def test_source_database_config
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: source_db_config_key).configuration_hash
  rescue ArgumentError
    ActiveRecord::Base.configurations.configs_for(env_name: "test", spec_name: source_db_config_key).config
  end

  def test_dump_database_config
    ActiveRecord::Base.configurations.configs_for(env_name: "test", name: dump_db_config_key).configuration_hash
  rescue ArgumentError
    ActiveRecord::Base.configurations.configs_for(env_name: "test_dump", spec_name: dump_db_config_key).config
  end
end

RSpec.configure do |config|
  config.include DatabaseHelper
end
